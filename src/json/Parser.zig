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

allocator: Allocator,
source: std.json.Scanner,
slurm_arena: std.heap.ArenaAllocator,

const TokenType = @typeInfo(Token).@"union".tag_type.?;

pub fn parse(comptime S: openapi.SchemaComponent, allocator: Allocator, text: []const u8) !getApiType(S) {
    var parser: Parser = .{
        .allocator = allocator,
        .source = std.json.Scanner.initCompleteInput(allocator, text),
        .slurm_arena = .init(slurm.slurm_allocator),
    };
    return parser.parseSchema(S);
}

// TODO: Remove this function again, just a hack for now
fn getApiType(comptime S: openapi.SchemaComponent) type {
    if (@hasDecl(S.api_type, "ItemType")) return *S.api_type;
    return S.api_type;
}

pub fn parseSchema(self: *Parser, comptime S: openapi.SchemaComponent) !getApiType(S) {
    switch (S.serde.sx) {
        .object => |o| switch (o) {
            .container => return try self.container(S),
            else => @compileError("unsupported"),
        },
        .array => |a| switch (a) {
            .list => return try self.arrayContainerToList(S),
            .assocs_short => return try self.assocsShort(),
            .container => {
                try self.expectNextToken(.array_begin);

                var list: S.api_type = .empty;
                while (true) {
                    const Child = S.getChild();
                    const item = try self.allocator.create(Child.api_type);
                    item.* = try self.parseSchema(Child);
                    try list.append(self.allocator, item);

                    if (.array_end == try self.source.peekNextTokenType()) break;
                }
                try self.expectNextToken(.array_end);
                return list;
            },
            else => @compileError("Unsupported Array Schema " ++ @typeName(S.api_type)),
        },
        else => {},
    }
}

pub fn parseProperty(self: *Parser, comptime P: openapi.Property, comptime T: type) !T {
    if (P.ref) |ref| {
        return self.parseSchema(ref);
    }

    switch (P.serde.sx) {
        .object => |o| switch (o) {
            .number, .number_zero_is_noval => {
                const num = try self.parseSchema(openapi.Number(T));
                return if (num.infinite) |_|
                    @field(slurm.common.Infinite, @typeName(T))
                else if (num.value) |v|
                    v
                else
                    @field(slurm.common.NoValue, @typeName(T));
            },
            else => @compileError("unsupported " ++ P.name),
        },
        .@"null" => {},
        .array => |a| switch (a) {
            .csv => return try self.arrayStrings(),
            .nested_bitflag, .bitflag => {
                const value = try self.innerParse([]const []const u8);
                return .fromSlice(value);
            },
            else => @compileError("array " ++ @tagName(a) ++ " not yet supported for " ++ @typeName(T) ++ " on field " ++ P.api_name),
        },
        .boolean => |b| switch (b) {
            .int => {
                const val = try self.innerParse(bool);
                return if (val) 1 else 0;
            },
            .native => return try self.innerParse(bool),
        },
        .dict => |d| switch (d) {
            .key_value => return try self.dict(),
            else => @compileError("dict not yet supported"),
        },
        .integer => |i| switch (i) {
            .signal => @compileError("TODO"),
            inline else => return try self.innerParse(T),
        },
        .number => |_| @compileError("number is not supported"),
        .string => |s| switch (s) {
            .user_name => @compileError("TODO"),
            .@"enum" => return try self.innerParse(T),
            inline else => return try self.innerParse([:0]const u8),
        },
    }

    @compileError("Invalid Parser type");
}

pub fn dict(self: *Parser) ![:0]const u8 {
    try self.expectNextToken(.object_begin);

    var kv_list: std.Io.Writer.Allocating = .init(self.allocator);
    defer kv_list.deinit();

    var writer = &kv_list.writer;
    var first = true;

    while (true) {
        const field_name = try self.nextFieldName() orelse break;

        if (!first) try writer.writeByte(',') else first = false;

        const value_token = try self.nextAlloc(.alloc_always);
        const v = switch (value_token) {
            inline .allocated_string, .allocated_number => |slice| slice,
            else => return error.UnexpectedToken,
        };
        try writer.writeAll(field_name);
        try writer.writeByte('=');
        try writer.writeAll(v);
    }
    return try kv_list.toOwnedSliceSentinel(0);
}

pub fn arrayStrings(self: *Parser) ![:0]const u8 {
    try self.expectNextToken(.array_begin);

    var aw: std.Io.Writer.Allocating = .init(self.allocator);
    defer aw.deinit();

    var writer = &aw.writer;
    var first = true;

    while (true) {
        const item = try self.nextFieldName() orelse break;
        if (!first) try writer.writeByte(',') else first = false;
        try writer.writeAll(item);
    }
    return try aw.toOwnedSliceSentinel(0);
}

pub fn assocsShort(self: *Parser) !*slurm.db.List(*slurm.db.Association) {
    try self.expectNextToken(.array_begin);

    var list: *slurm.db.List(*slurm.db.Association) = .init();
    while (true) {
        const T = baseType(@TypeOf(list)).ItemType;
        const TBase = baseType(T);
        const item: T = try self.slurm_arena.allocator().create(TBase);
        const assoc_short = try self.parseSchema(openapi.AssociationShort);
        item.* = .{};
        item.acct = assoc_short.account;
        item.cluster = assoc_short.cluster;
        item.id = assoc_short.id;
        item.partition = assoc_short.partition;
        item.user = assoc_short.user;
        list.append(item);

        if (.array_end == try self.source.peekNextTokenType()) break;
    }
    try self.expectNextToken(.array_end);
    return list;
}

pub fn arrayContainerToList(self: *Parser, comptime S: openapi.SchemaComponent) !*S.api_type {
    try self.expectNextToken(.array_begin);

    var list: *S.api_type = .init();
    while (true) {
        const T = baseType(@TypeOf(list)).ItemType;
        const TBase = baseType(T);
        const item: T = try self.slurm_arena.allocator().create(TBase);
        item.* = try self.parseSchema(S.getChild());
        list.append(item);

        if (.array_end == try self.source.peekNextTokenType()) break;
    }
    try self.expectNextToken(.array_end);
    return list;
}

pub fn innerParse(self: *Parser, comptime T: type) !T {
    return try std.json.innerParse(
        T, self.allocator, &self.source,
        .{ .allocate = .alloc_always, .max_value_len = self.source.input.len
    });
}

fn fieldNameFromToken(t: Token) !?[]const u8 {
    return switch (t) {
        inline .string, .allocated_string, .number, .allocated_number => |slice| slice,
        .object_end, .array_end => null,
        else => error.UnexpectedToken,
    };
}

fn nextAlloc(self: *Parser, when: std.json.AllocWhen) !Token {
    return try self.source.nextAllocMax(self.allocator, when, self.source.input.len);
}

fn nextFieldName(self: *Parser) !?[]const u8 {
    const token = try self.nextAlloc(.alloc_if_needed);
    return fieldNameFromToken(token);
}

fn expectNextToken(self: *Parser, token: TokenType) !void {
    if (token != try self.source.next()) return error.UnexpectedToken;
}

pub fn container(self: *Parser, comptime S: openapi.SchemaComponent) !S.api_type {
    var fields_seen: [S.properties.len]bool = @splat(false);

    var result: S.api_type = .{};
    try self.expectNextToken(.object_begin);
    while (true) {
        const field_name = try self.nextFieldName() orelse break;
        inline for (S.properties, 0..) |prop, i| {
            if (std.mem.eql(u8, prop.name, field_name)) {
                if (fields_seen[i]) {
                    return error.DuplicateField;
                }
                const api_name = prop.api_name orelse prop.name;
                const field = @field(result, api_name);
                const T = @TypeOf(field);

                @field(result, api_name) = try self.parseProperty(prop, T);
                fields_seen[i] = true;
                break;
            }
        } else {
            std.debug.print("unknown token: {s}\n", .{field_name});
            return error.UnknownField;
        }
    }

    return result;
//    try fillDefaultStructValues(S.api_type, r, &fields_seen);
    //std.debug.print("token is {}\n", .{try self.source.peekNextTokenType()});
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
