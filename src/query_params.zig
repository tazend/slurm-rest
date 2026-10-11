const std = @import("std");
const mem = std.mem;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const httpz = @import("httpz");
const RequestContext = @import("route.zig").RequestContext;
const RouteData = @import("route.zig").RouteData;
pub const ParameterParser = @This();

arena: std.mem.Allocator,
request: *httpz.Request,
qos: ?*slurm.List(*slurm.db.QoS) = null,
db_conn: ?*slurm.db.Connection = null,

pub fn init(ctx: *RequestContext, qos: ?*slurm.List(*slurm.db.QoS), db_conn: ?*slurm.db.Connection) ParameterParser {
    return .{
        .arena = ctx.arena,
        .request = ctx.req,
        .db_conn = db_conn,
        .qos = qos,
    };
}

pub const Style = enum {
    simple,
    form,
};

pub const ParserType = enum {
    list,
    list_qos_ids,
    flags,
    flags_int,
    string,
    integer,
    @"enum",
};

pub const Reference = struct {
    name: [:0]const u8,
    component: QueryParameterComponent,
};

pub const Parameter = struct {
    api_name: ?[:0]const u8 = null,
    name: [:0]const u8,
    description: []const u8,
    required: bool = false,
    style: Style = .form,
    explode: bool = true,
    parser: ParserType,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.beginObject();

        try jw.objectField("in");
        try jw.write("query");
        try jw.objectField("name");
        try jw.write(self.name);
        try jw.objectField("description");
        try jw.write(self.description);
        try jw.objectField("required");
        try jw.write(self.required);
        try jw.objectField("style");
        try jw.write(self.style);
        try jw.objectField("explode");
        try jw.write(self.explode);

        try jw.objectField("schema");
        try jw.beginObject();
        // TODO: Figure out the proper json type
        try jw.objectField("type");
        try jw.write("string");
        try jw.endObject();
        try jw.endObject();
    }
};

pub const QueryParameterComponent = struct {
    api_type: type,
    parameters: []const Parameter = &.{},
    refs: []const Reference = &.{},

    pub const init = parse;
};

pub fn initType(comptime T: type, arena: std.mem.Allocator) !T {
    switch (@typeInfo(T)) {
        .optional => |o| return try initType(o.child, arena),
        .pointer => |p| {
            const x = try arena.create(p.child);
            x.* = try initType(p.child, arena);
            return x;
        },
        .@"struct" => return .{},
        else => @compileError("Unsupported Type"),
    }
}

pub fn parse(self: *ParameterParser, comptime T: QueryParameterComponent) !T.api_type {
    var f: T.api_type = .{};
    var query = try self.request.query();
    var query_it = query.iterator();
    var refs_inited: [T.refs.len]bool = @splat(false);

    while (query_it.next()) |kv| {
        try self.processParamsForQueryItem(T, &refs_inited, &f, kv.key, kv.value);
    }
    return f;
}

pub fn processParamsForQueryItem(self: *ParameterParser, comptime Q: QueryParameterComponent, refs_inited: *[Q.refs.len]bool, f: *Q.api_type, key: []const u8, value: []const u8) !void {
    inline for (Q.parameters) |param| {
        if (std.mem.eql(u8, key, param.name)) {
            try self.parseParam(f, value, param);
            return;
        }
    }
    inline for (Q.refs, 0..) |ref, i| {
        const r = &@field(f, ref.name);
        const RefType = @TypeOf(r.*);

        if (!refs_inited[i]) {
            r.* = try initType(RefType, self.arena);
            refs_inited[i] = true;
        }

        const real = if (@typeInfo(RefType) == .optional)
            // Assume the unwrapped optional is a pointer for now
            r.*.?
        else
            r;

        inline for (ref.component.parameters) |param| {
            if (std.mem.eql(u8, key, param.name)) {
                try self.parseParam(real, value, param);
                return;
            }
        }
    }
    return error.InvalidQueryParameter;
}

fn isInteger(s: []const u8) bool {
    _ = std.fmt.parseInt(usize, s, 10) catch return false;
    return true;
}

fn ensureQoSLoaded(self: *ParameterParser) !void {
    if (self.qos == null) {
        if (self.db_conn == null) self.db_conn = try slurm.db.Connection.open();
        self.qos = try slurm.db.qos.load(self.db_conn.?, .{});
    }
}

fn qosNameToId(qos: *slurm.List(*slurm.db.QoS), name: []const u8) ?u32 {
    var it = qos.iter();
    defer it.deinit();

    while (it.next()) |i| {
        const n = slurm.parseCStr(i.name) orelse continue;
        if (std.mem.eql(u8, n, name)) return i.id;
    } else return null;
}

pub fn parseParam(self: *ParameterParser, r: anytype, value: []const u8, comptime P: Parameter) anyerror!void {
    const fname = P.api_name orelse P.name;
    const field = &@field(r, fname);

    const T = @TypeOf(field.*);
    switch (P.parser) {
        .string => {
            const v = try self.arena.dupeZ(u8, value);
            field.* = v;
        },
        .integer => field.* = std.fmt.parseInt(T, value, 10) catch return error.InvalidNumber,
        .@"enum" => field.* = std.meta.stringToEnum(T, value) orelse return error.InvalidEnumValue,
        .flags, .flags_int => |f| {
            if (std.mem.eql(u8, value, "true")) {
                field.* = if (f == .flags) true else 1;
            } else if (std.mem.eql(u8, value, "false")) {
                field.* = if (f == .flags) false else 0;
            } else return error.InvalidBooleanValue;
        },
        .list => {
            // TODO: Need to free it
            if (field.* == null) field.* = .initNoDestroyItems();
            const item = try self.arena.dupeZ(u8, value);
            field.*.?.append(item);

        },
        .list_qos_ids => {
            if (field.* == null) field.* = .initNoDestroyItems();

            const value_fmt = if (!isInteger(value)) blk: {
                try self.ensureQoSLoaded();
                if (qosNameToId(self.qos.?, value)) |id|
                    break :blk try std.fmt.allocPrintSentinel(self.arena, "{d}", .{id}, 0)
                else
                    // NOTE: Maybe Error on invalid QoS?
                    break :blk try self.arena.dupeZ(u8, value);
            } else try self.arena.dupeZ(u8, value);

            field.*.?.append(value_fmt);
        },
    }
}
