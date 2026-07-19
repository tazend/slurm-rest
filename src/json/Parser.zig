const std = @import("std");
const Allocator = std.mem.Allocator;
const slurm = @import("slurm");
const Parser = @This();
const openapi = @import("../openapi.zig");
const Dumper = @import("Dumper.zig");
const Stringify = std.json.Stringify;
const Token = std.json.Token;

pub const ParseFN = *const fn(parser: *Parser, ctx: Context, ret: anytype) anyerror!void;

allocator: Allocator,
source: std.json.Scanner,

pub const Context = struct {
    field: ?openapi.Property = null,
    schema: openapi.SchemaComponent,
};

pub fn parse(comptime T: type, allocator: Allocator, text: []const u8) !T {
    var parser: Parser = .{
        .allocator = allocator,
        .source = std.json.Scanner.initCompleteInput(allocator, text),
    };
    const schema = Dumper.getSchema(T);
    var ret: schema.api_type = undefined;
    const ctx: Context = .{
        .field = null,
        .schema = schema,
    };
    try schema.serde.parse(&parser, ctx, &ret);
    return ret;
}

pub fn native(parser: *Parser, ctx: Context, r: anytype) !void {
    r.* = try std.json.innerParse(
        ctx.schema.api_type, parser.allocator, &parser.source,
        .{ .allocate = .alloc_always, .max_value_len = parser.source.input.len
    });
}

pub fn unsupported(_: *Parser, _: Context, _: anytype) !void {
    @compileError("Parsing for this Type is not supported.");
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
    return try aw.toOwnedSliceSentinel(0);
}

pub fn array(parser: *Parser, ctx: Context, r: anytype) !void {
    @field(r, ctx.field.?.name) = try arrayRaw(parser);
}

pub fn arrayBitflag(parser: *Parser, ctx: Context, r: anytype) !void {
    const value = try std.json.innerParse(
        []const []const u8, parser.allocator, &parser.source,
        .{ .allocate = .alloc_always, .max_value_len = parser.source.input.len
    });
    @field(r, ctx.field.?.name) = .fromSlice(value);
}

pub fn string(parser: *Parser, ctx: Context, r: anytype) !void {
    const value = try std.json.innerParse(
        [:0]const u8, parser.allocator, &parser.source,
        .{ .allocate = .alloc_always, .max_value_len = parser.source.input.len
    });
    @field(r, ctx.field.?.name) = value;
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
    @field(r, ctx.field.?.name) = try kv_list.toOwnedSliceSentinel(0);
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
                const new_ctx: Context = .{
                    .field = prop,
                    .schema = ctx.schema,
                };
//                std.debug.print("processing: {s}\n", .{prop.name});
                try prop.serde.parse(parser, new_ctx, r);
                fields_seen[i] = true;
                break;
            }
        } else {
            std.debug.print("unknown token: {s}\n", .{name_token.string});
            return error.UnknownField;
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
