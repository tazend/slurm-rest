const std = @import("std");
const Allocator = std.mem.Allocator;
const slurm = @import("slurm");
const Parser = @This();
const openapi = @import("../openapi.zig");
const Dumper = @import("Dumper.zig");
const Stringify = std.json.Stringify;
const Token = std.json.Token;
const baseType = Dumper.baseType;
const models = @import("../models.zig");

pub const ParseFN = *const fn(parser: *Parser, ctx: Context, ret: anytype) anyerror!void;

allocator: Allocator,
source: std.json.Scanner,
slurm_arena: std.heap.ArenaAllocator,

pub const Context = struct {
    field: ?[:0]const u8 = null,
    schema: openapi.SchemaComponent,
};

pub fn parse(comptime T: type, allocator: Allocator, text: []const u8) !T {
    var parser: Parser = .{
        .allocator = allocator,
        .source = std.json.Scanner.initCompleteInput(allocator, text),
        .slurm_arena = .init(slurm.slurm_allocator),
    };
    return try parseRequireSchema(T, &parser);
}

pub fn parse2(comptime T: openapi.SchemaComponent, allocator: Allocator, text: []const u8) !T.api_type {
    var parser: Parser = .{
        .allocator = allocator,
        .source = std.json.Scanner.initCompleteInput(allocator, text),
        .slurm_arena = .init(slurm.slurm_allocator),
    };
    var ret: T.api_type = .{};
    const new_ctx: Context = .{
        .field = null,
        .schema = T,
    };
    try T.serde.parse(&parser, new_ctx, &ret);
    if (T.api_type == slurm.Partition) {
        std.debug.print("name sdsd: {?s}\n", .{ret.name});
    }
    return ret;
}

pub fn parseRequireSchema(comptime T: type, parser: *Parser) !T {
    const schema = Dumper.getSchema(T);
    var ret: schema.api_type = undefined;
    const new_ctx: Context = .{
        .field = null,
        .schema = schema,
    };
    try schema.serde.parse(parser, new_ctx, &ret);
    return ret;
}

pub fn parseWithSchema(comptime S: openapi.SchemaComponent, parser: *Parser) anyerror!S.api_type {
    var ret: S.api_type = undefined;
    const new_ctx: Context = .{
        .field = null,
        .schema = S,
    };
    try S.serde.parse(parser, new_ctx, &ret);
    return ret;
}

pub fn native(parser: *Parser, ctx: Context, r: anytype) !void {
    r.* = try std.json.innerParse(
        ctx.schema.api_type, parser.allocator, &parser.source,
        .{ .allocate = .alloc_always, .max_value_len = parser.source.input.len
    });
}

pub fn unsupported(_: *Parser, ctx: Context, r: anytype) !void {
    @compileError("Parsing '" ++ ctx.field.? ++ "' is not supported in type: " ++ @typeName(@TypeOf(r)));
}

pub fn noop(parser: *Parser, ctx: Context, r: anytype) !void {
    _ = ctx;
    _ = r;
    _ = parser;
}

pub fn arrayRaw(parser: *Parser) ![:0]const u8 {
    if (.array_begin != try parser.source.next()) return error.UnexpectedToken;

    var aw: std.Io.Writer.Allocating = .init(parser.allocator);
    defer aw.deinit();

    var writer = &aw.writer;
    var first = true;

    while (true) {
        const token: Token = try parser.source.nextAllocMax(parser.allocator, .alloc_if_needed, parser.source.input.len);
        const item = try fieldNameFromToken(token) orelse break;

        if (!first) try writer.writeByte(',') else first = false;
        try writer.writeAll(item);
    }
    // TODO: Maybe need to advance cursor and check for array_end
    return try aw.toOwnedSliceSentinel(0);
}

pub fn arrayContainerToList(parser: *Parser, ctx: Context, r: anytype) !void {
    if (.array_begin != try parser.source.next()) return error.UnexpectedToken;

    var list = @field(r, ctx.field.?);
    list = .init();
    defer @field(r, ctx.field.?) = list;

    while (true) {
        const T = baseType(@TypeOf(list)).ItemType;
        const TBase = baseType(T);
        const item: T = try parser.slurm_arena.allocator().create(TBase);

        item.* = try parseRequireSchema(TBase, parser);
        list.?.append(item);

        if (.array_end == try parser.source.peekNextTokenType()) break;
    }
    if (.array_end != try parser.source.next()) return error.UnexpectedToken;
}

pub fn array(parser: *Parser, ctx: Context, r: anytype) !void {
    @field(r, ctx.field.?) = try arrayRaw(parser);
}

pub fn assocsShort(parser: *Parser, ctx: Context, r: anytype) !void {
    if (.array_begin != try parser.source.next()) return error.UnexpectedToken;
    const field_name = ctx.field.?;

    var list = @field(r, field_name);
    list = .init();
    defer @field(r, field_name) = list;

    while (true) {
        const T = baseType(@TypeOf(list)).ItemType;
        const TBase = baseType(T);
        const item: T = try parser.slurm_arena.allocator().create(TBase);

        const assoc_short = try parseRequireSchema(models.AssociationShort, parser);
        item.acct = assoc_short.account;
        item.cluster = assoc_short.cluster;
        item.id = assoc_short.id;
        item.partition = assoc_short.partition;
        item.user = assoc_short.user;
        list.?.append(item);

        if (.array_end == try parser.source.peekNextTokenType()) break;
    }
    if (.array_end != try parser.source.next()) return error.UnexpectedToken;
}

pub fn arrayBitflag(parser: *Parser, ctx: Context, r: anytype) !void {
    const value = try innerParse([]const []const u8, parser);
    @field(r, ctx.field.?) = .fromSlice(value);
}

pub fn string(parser: *Parser, ctx: Context, r: anytype) !void {
    const name = try std.json.innerParse(
        [:0]const u8, parser.allocator, &parser.source,
        .{ .allocate = .alloc_always, .max_value_len = parser.source.input.len
    });
    @field(r, ctx.field.?) = name;
}

pub fn number(parser: *Parser, ctx: Context, r: anytype) !void {
    const T = @TypeOf(@field(r, ctx.field.?));
    const num = try parseWithSchema(openapi.Number(T), parser);
    @field(r, ctx.field.?) = if (num.infinite) |_|
        @field(slurm.common.Infinite, @typeName(T))
    else if (num.value) |v|
        v
    else
        @field(slurm.common.NoValue, @typeName(T));
}

pub fn @"enum"(parser: *Parser, ctx: Context, r: anytype) !void {
    const T = @TypeOf(@field(r, ctx.field.?));
    @field(r, ctx.field.?) = try innerParse(T, parser);
}

pub fn integer(parser: *Parser, ctx: Context, r: anytype) !void {
    const T = @TypeOf(@field(r, ctx.field.?));
    @field(r, ctx.field.?) = try innerParse(T, parser);
}

pub fn innerParse(comptime T: type, parser: *Parser) !T {
    return try std.json.innerParse(
        T, parser.allocator, &parser.source,
        .{ .allocate = .alloc_always, .max_value_len = parser.source.input.len
    });
}

pub fn dict(parser: *Parser, ctx: Context, r: anytype) !void {
    if (.object_begin != try parser.source.next()) return error.UnexpectedToken;

    var kv_list: std.Io.Writer.Allocating = .init(parser.allocator);
    defer kv_list.deinit();

    var writer = &kv_list.writer;
    var first = true;

    while (true) {
        const name_token: Token = try parser.source.nextAllocMax(parser.allocator, .alloc_if_needed, parser.source.input.len);
        const field_name = try fieldNameFromToken(name_token) orelse break;

        if (!first) try writer.writeByte(',') else first = false;

        const value_token: Token = try parser.source.nextAllocMax(parser.allocator, .alloc_always, parser.source.input.len);

        const v = switch (value_token) {
            inline .allocated_string, .allocated_number => |slice| slice,
            else => return error.UnexpectedToken,
        };
        try writer.writeAll(field_name);
        try writer.writeByte('=');
        try writer.writeAll(v);
    }
    @field(r, ctx.field.?) = try kv_list.toOwnedSliceSentinel(0);

    // TODO: Maybe need to advance cursor and check for object_end
}

fn fieldNameFromToken(t: Token) !?[]const u8 {
    return switch (t) {
        inline .string, .allocated_string, .number, .allocated_number => |slice| slice,
        .object_end, .array_end => null,
        else => error.UnexpectedToken,
    };
}

pub fn container(parser: *Parser, ctx: Context, r: anytype) !void {
    const api_type_fields = @typeInfo(ctx.schema.api_type).@"struct".fields;
    var fields_seen: [api_type_fields.len]bool = @splat(false);

    if (ctx.field) |f| {
        @field(r, f) = try parseWithSchema(ctx.schema, parser);
        return;
    }

    if (.object_begin != try parser.source.next()) return error.UnexpectedToken;
    while (true) {
        const name_token: Token = try parser.source.nextAllocMax(parser.allocator, .alloc_if_needed, parser.source.input.len);
        const field_name = try fieldNameFromToken(name_token) orelse break;
        inline for (ctx.schema.properties, 0..) |prop, i| {
//            std.debug.print("name token: {s}, api_name: {s}\n", .{name_token.string, prop.name});
            if (std.mem.eql(u8, prop.name, field_name)) {
                if (fields_seen[i]) {
                    return error.DuplicateField;
                }

                std.debug.print("processing: {s}\n", .{prop.name});
                const new_ctx: Context = .{
                    .field = prop.api_name orelse prop.name,
                    .schema = prop.ref orelse ctx.schema,
                };
                try prop.serde.parse(parser, new_ctx, r);
                if (ctx.schema.api_type == slurm.Partition) {
                    std.debug.print("name is: {?s}\n", .{r.name});
                }
                fields_seen[i] = true;
                break;
            }
        } else {
            std.debug.print("unknown token: {s}\n", .{name_token.string});
            return error.UnknownField;
        }
    }

    try fillDefaultStructValues(ctx.schema.api_type, r, &fields_seen);
//  std.debug.print("token is {}\n", .{try parser.source.peekNextTokenType()});
//  if (.object_end != try parser.source.next()) return error.UnexpectedToken;
//  std.debug.print("token is {}\n", .{try parser.source.peekNextTokenType()});
}

fn fillDefaultStructValues(comptime T: type, r: *T, fields_seen: *[@typeInfo(T).@"struct".fields.len]bool) !void {
    std.debug.print("fields seen: {any}\n", .{fields_seen});
    inline for (@typeInfo(T).@"struct".fields, 0..) |field, i| {
        if (!fields_seen[i]) {
            if (field.defaultValue()) |default| {
                @field(r, field.name) = default;
            } else {
                return error.MissingField;
            }
        } else {
            std.debug.print("skipping set field: {s}\n", .{field.name});
        }
    }
}

test {
//  const text =
//      \\{ "tres": { "cpu": 1, "mem": "2G" }, "partitions": [ "normal" ] }
//  ;
    const text =
        \\{ "comment": "This is my comment", "features": [ "bla", "buu" ], "gres": { "cpu": 3, "mem": "2G" }, "cpu_bind": [ "verbose" ] }
    ;
    const unode = try parse(slurm.Node.Updatable, std.heap.page_allocator, text);
    std.debug.print("comment: {?s}\n", .{unode.comment});
    std.debug.print("features: {?s}\n", .{unode.features});
    std.debug.print("gres: {?s}\n", .{unode.gres});
    std.debug.print("cpu_bind: {}\n", .{unode.cpu_bind});
}
