const std = @import("std");
const Allocator = std.mem.Allocator;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const Dumper = @This();
const openapi = @import("../openapi.zig");
const models = @import("../models.zig");
const SerdeContext = @import("SerdeContext.zig");
const j = @import("../json.zig");
const types = j.types;
const uidToNameBuf = @import("../util.zig").uidToNameBuf;
const SchemaComponent = openapi.SchemaComponent;
const Property = openapi.Property;

json: Stringify,
allocator: Allocator,

pub fn init(allocator: Allocator, writer: *std.Io.Writer) Dumper {
    return .{
        .allocator = allocator,
        .json = .{
            .options = .{},
            .writer = writer,
        },
    };
}

pub fn dump(allocator: Allocator, value: anytype, comptime S: SchemaComponent) ![]const u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    var dumper: Dumper = .init(allocator, &aw.writer);
    try dumper.dumpSchema(value, S);
    return aw.toOwnedSlice();
}

pub fn dumpSchema(self: *Dumper, value: anytype, comptime S: SchemaComponent) !void {
    switch (S.serde.sx) {
        .object => |o| switch (o) {
            .container => try self.container(value, S),
            else => @compileError("Unsuppored object schema dumper"),
        },
        .array => |a| switch (a) {
            .list => try self.list(value, S),
            .assocs_short => try self.assocsShort(value),
            .load_response => try self.loadResponse(value, S.getChild()),
            else => {},
        },
        else => {},
    }
}

pub fn dumpProperty(self: *Dumper, comptime S: SchemaComponent, instance: anytype, comptime P: Property) !void {
    // Just skip immediately, since this is explicitly marked as a no-op.
    if (P.serde.sx == .@"null") return;

    const fname = P.api_name orelse P.name;
    try self.json.objectField(P.name);

    const value = if (@hasDecl(S.api_type, fname))
        @field(S.api_type, fname)
    else
        @field(instance, fname);

    switch (P.serde.sx) {
        .object => |o| switch (o) {
            .number => try self.numberRaw(value, .{}),
            .number_zero_is_noval => try self.numberRaw(value, .{ .zero_is_noval = true }),
            .container => {
                return self.container(value, P.getRef());
            },
            .native => try self.json.write(value),
            .node_state => {
                const state = if (@as(u32, @bitCast(value)) != slurm.common.NoValue.u32)
                    @tagName(value.base)
                else
                    null;
                try self.json.write(state);
            },
        },
        // This is explicitly marked as a no-op
        .@"null" => {},
        .array => |a| switch (a) {
            .csv => try self.array(value, .{}),
            .nested_bitflag => {
                const T = @typeInfo(@TypeOf(instance)).@"struct".backing_integer.?;
                if (slurm.common.numberHasValue(@as(T, @bitCast(instance)))) {
                    try self.json.write(instance);
                } else {
                    try self.json.print("[]", .{});
                }
            },
            .list => return self.list(value, P.getRef()),
            .load_response => @compileError("Found load_response dumper on a property."),
            .native, .bitflag, .container => try self.json.write(value),
            .integers => try self.array(value, .{ .numbers = true }),
            .assocs_short => return self.assocsShort(value),
            .reservation_core_specs => try self.arrayWithExternalSize(value, instance.core_spec_cnt, P.getRefChild()),
        },
        .boolean => |b| switch (b) {
            .int => if (value == 0) try self.json.write(false) else try self.json.write(true),
            .native => try self.json.write(value),
        },
        .dict => |d| switch (d) {
            .key_value => try self.dict(value, .{}),
            .gres_count => try self.gresDict(value),
        },
        .integer => |i| switch (i) {
            .method_number_flat => {
                const v = value(instance);
                try self.json.write(v);
            },
            .method_number, .job_memory, .job_memory_total => {
                const v = value(instance);
                try self.numberRaw(v, .{});
            },
            .std => try self.json.write(value),
            .node_idle_cpus => {
                const util = value(instance);
                try self.json.write(util.idle_cpus);
            },
            .native => try self.numberRaw(value, .{ .flat = true }),
            .native_zero_is_noval => try self.numberRaw(value, .{ .flat = true, .zero_is_noval = true }),
            .native_infinite_is_null => {
                if (slurm.common.numberIsInfinite(value)) {
                    try self.json.write(null);
                } else try self.numberRaw(value, .{ .flat = true });
            },
            .timestamp => {
                const time = if (value != 0) value else null;
                try self.json.write(time);
            },
        },
        .number => |_| @compileError("Got 'number' type on Property"),
        .string => |s| switch (s) {
            .@"enum", .native => try self.json.write(value),
            .print => try self.json.print("{?s}", .{value}),
            .job_stdout, .job_stderr, .job_stdin => {
                var buf: [std.c.PATH_MAX]u8 = undefined;
                const path = instance.getStdioPath(value, &buf) catch null;
                try self.json.write(path);
            },
            .reason_user, .user_name => {
                var buf: [std.c.NAME_MAX]u8 = undefined;
                const v = try uidToNameBuf(&buf, value);
                try self.json.write(v);
            },
            .step_id => {
                var buf: [128]u8 = undefined;
                const v = value(instance, &buf) catch null;
                try self.json.write(v);
            },
            .sluid => {
                var buf: [15:0]u8 = undefined;
                const v = value(instance, &buf);
                try self.json.write(v);
            },
        },
    }
}

pub fn assocsShort(self: *Dumper, value: anytype) !void {
    try self.json.beginArray();
    if (value) |assocs| {
        var it = assocs.iter();
        while (it.next()) |assoc| {
            const assoc_short: types.AssociationShort = .{
                .account = assoc.acct,
                .cluster = assoc.cluster,
                .user = assoc.user,
                .partition = assoc.partition,
                .id = assoc.id,
            };
            try self.json.write(assoc_short);
        }
    }
    try self.json.endArray();
}

pub fn container(self: *Dumper, instance: anytype, comptime S: SchemaComponent) !void {
    try self.json.beginObject();
    const v = switch (@typeInfo(@TypeOf(instance))) {
        .optional => if (instance) |i| i else return try self.json.endObject(),
        else => instance,
    };
    inline for (S.properties) |prop| {
        try self.dumpProperty(S, v, prop);
    }
    try self.json.endObject();
}

pub fn list(self: *Dumper, instance: anytype, comptime S: SchemaComponent) !void {
    const List = S.api_type;
    const it: ?*List.Iterator = switch (@typeInfo(@TypeOf(instance))) {
        .optional => if (instance) |i| i.iter() else null,
        else => instance.iter(),
    };
    try self.json.beginArray();
    if (it) |i| {
        while (i.next()) |item| {
            try self.dumpSchema(item, S.getChild());
        }
    }
    try self.json.endArray();
}

pub fn loadResponse(self: *Dumper, instance: anytype, comptime Child: SchemaComponent) !void {
    try self.json.beginArray();
    var iter = instance.iter();
    while (iter.next()) |item| {
        try self.dumpSchema(item, Child);
    }
    try self.json.endArray();
}

const ArrayOptions = struct {
    sep: u8 = ',',
    numbers: bool = false,
};

pub fn arrayWithExternalSize(self: *Dumper, value: anytype, size: u64, comptime Child: SchemaComponent) !void {
    try self.json.beginArray();
    const v = switch (@typeInfo(@TypeOf(value))) {
        .optional => if (value) |i| i else return try self.json.endArray(),
        else => value,
    };
    for (0..size) |i| {
        try self.dumpSchema(v[i], Child);
    }
    try self.json.endArray();
}

pub fn array(self: *Dumper, value: anytype, comptime options: ArrayOptions) !void {
    const buf = slurm.parseCStrZ(value) orelse {
        try self.json.print("[]", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf) or buf.len == 0) {
        try self.json.print("[]", .{});
        return;
    }

    try self.json.beginArray();
    var it = std.mem.splitScalar(u8, buf, options.sep);
    while (it.next()) |item| {
        switch (options.numbers) {
            true => {
                const v = std.fmt.parseInt(u64, item, 10) catch continue;
                try self.json.write(v);
            },
            false => try self.json.write(item),
        }
    }
    try self.json.endArray();
}

pub fn resCoreSpec(self: *Dumper, instance: *slurm.Reservation) !void {
    if (instance.core_spec_cnt == slurm.common.NoValue.u32 or instance.core_spec == null) {
        try self.json.print("[]", .{});
        return;
    }

    try self.json.beginArray();
    for (0..instance.core_spec_cnt) |i| {
        const spec = instance.core_spec.?[i];
        const name = slurm.parseCStr(spec.node_name) orelse continue;
        const id = slurm.parseCStr(spec.core_id) orelse continue;

        try self.json.beginObject();
        try self.json.objectField("name");
        try self.json.write(name);
        try self.json.objectField("id");
        try self.json.write(id);
        try self.json.endObject();
    }
    try self.json.endArray();
}

pub fn gresDict(self: *Dumper, value: anytype) !void {
    const buf = slurm.parseCStrZ(value) orelse {
        try self.json.print("{{}}", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf)) {
        try self.json.print("{{}}", .{});
        return;
    }

    var it = std.mem.splitScalar(u8, buf, ',');
    try self.json.beginObject();
    while (it.next()) |item| {
        var it_inner = std.mem.splitBackwardsScalar(u8, item, ':');
        const count = it_inner.first();
        const key = it_inner.rest();

        try self.json.objectField(key);
        try self.json.write(count);
    }
    try self.json.endObject();
}

const DictOptions = struct {
    sep1: u8 = ',',
    sep2: u8 = '=',
};

pub fn dict(self: *Dumper, value: anytype, comptime options: DictOptions) !void {
    const buf = slurm.parseCStrZ(value) orelse {
        try self.json.print("{{}}", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf)) {
        try self.json.print("{{}}", .{});
        return;
    }

    try self.json.beginObject();
    var it_outer = std.mem.splitScalar(u8, buf, options.sep1);
    while (it_outer.next()) |item| {
        var it_inner = std.mem.splitScalar(u8, item, options.sep2);
        const key = it_inner.first();
        const val = it_inner.rest();
        const val_num = std.fmt.parseInt(u128, val, 10) catch null;

        try self.json.objectField(key);
        if (val_num) |v| {
            try self.json.write(v);
        } else try self.json.write(val);
    }
    try self.json.endObject();
}

pub fn Number(comptime T: type) type {
    return struct {
        value: ?T,
        infinite: ?bool = null,
    };
}

pub const NumberOptions = struct {
    zero_is_noval: bool = false,
    flat: bool = false,
};

pub fn numberRaw(self: *Dumper, data: anytype, opts: NumberOptions) !void {
    const T = @TypeOf(data);
    const raw_number = @as(T, data);

    const value: ?T = blk: {
        const has_value = slurm.common.numberHasValue(data);

        if ((opts.zero_is_noval and raw_number == 0) or !has_value) {
            break :blk null;
        } else {
            break :blk data;
        }
    };
    switch (opts.flat) {
        false => try self.json.write(Number(T){
            .value = value,
            .infinite = slurm.common.numberIsInfinite(data),
        }),
        true => try self.json.write(value),
    }
}

pub fn getSchema(comptime T: type) SchemaComponent {
    const decls = @typeInfo(openapi).@"struct".decls;
    const Child = comptime baseType(T);

    for (decls) |decl| {
        const field = @field(openapi, decl.name);
        if (@TypeOf(field) == SchemaComponent) {
            if (field.api_type == Child) {
                return field;
            }
        }
    }
    @compileError("No implementation found for " ++ @typeName(T));
}

pub fn baseType(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .optional, .pointer => blk: {
            const C = std.meta.Child(T);
            switch (@typeInfo(C)) {
                .pointer => break :blk std.meta.Child(C),
                else => break :blk C,
            }
        },
        else => T,
    };
}
