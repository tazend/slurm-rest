const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const slurm = @import("slurm");
const httpz = @import("httpz");
const openapi = @import("../openapi.zig");
const QueryParameterComponent = openapi.QueryParameterComponent;
const Parameter = QueryParameterComponent.Parameter;

const QueryParameters = @This();

arena: Allocator,
qos: ?*slurm.List(*slurm.db.QoS) = null,
db_conn: ?*slurm.db.Connection = null,

pub fn parse(
    self: *QueryParameters,
    comptime T: QueryParameterComponent,
    req: *httpz.Request
) !T.api_type {
    var result: T.api_type = .{};
    var query = try req.query();
    var query_it = query.iterator();
    var refs_inited: [T.refs.len]bool = @splat(false);

    while (query_it.next()) |kv| {
        try self.processParamsForQueryItem(T, &refs_inited, &result, kv.key, kv.value);
    }
    return result;
}

pub fn processParamsForQueryItem(
    self: *QueryParameters,
    comptime Q: QueryParameterComponent,
    refs_inited: *[Q.refs.len]bool,
    result: *Q.api_type,
    key: []const u8,
    value: []const u8
) !void {
    inline for (Q.parameters) |param| {
        if (mem.eql(u8, key, param.name)) {
            try self.parseParam(result, value, param);
            return;
        }
    }
    inline for (Q.refs, 0..) |ref, i| {
        const r = &@field(result, ref.name);
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
            if (mem.eql(u8, key, param.name)) {
                try self.parseParam(real, value, param);
                return;
            }
        }
    }
    return error.InvalidQueryParameter;
}

fn parseParam(
    self: *QueryParameters,
    result: anytype,
    value: []const u8,
    comptime P: Parameter
) !void {
    const fname = P.api_name orelse P.name;
    const field = &@field(result, fname);

    const T = @TypeOf(field.*);
    switch (P.parser) {
        .string => {
            const v = try self.arena.dupeZ(u8, value);
            field.* = v;
        },
        .integer => field.* = std.fmt.parseInt(T, value, 10) catch return error.InvalidNumber,
        .@"enum" => field.* = std.meta.stringToEnum(T, value) orelse return error.InvalidEnumValue,
        .flags, .flags_int => |f| {
            if (mem.eql(u8, value, "true")) {
                field.* = if (f == .flags) true else 1;
            } else if (mem.eql(u8, value, "false")) {
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

fn isInteger(s: []const u8) bool {
    _ = std.fmt.parseInt(usize, s, 10) catch return false;
    return true;
}

fn ensureQoSLoaded(self: *QueryParameters) !void {
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
        if (mem.eql(u8, n, name)) return i.id;
    } else return null;
}

fn initType(comptime T: type, arena: Allocator) !T {
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

