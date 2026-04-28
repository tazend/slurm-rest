const std = @import("std");
const mem = std.mem;
const slurm = @import("slurm");
const Stringify = std.json.Stringify;
const json = @import("../json.zig");
const types = json.types;

/// Skips a field / container entirely
pub fn noop(_: *Stringify, _: anytype, _: anytype, _: anytype) !void {}

const DictOptions = struct {
    sep1: u8 = ',',
    sep2: u8 = '=',
};

pub fn dict(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    const options: *const DictOptions = blk: {
        if (opts == null) {
            break :blk &.{};
        } else {
            break :blk @ptrCast(opts);
        }
    };

    const value = @field(instance, field.name);
    try s.objectField(field.json_key);

    const buf = slurm.parseCStrZ(value) orelse {
        try s.print("{{}}", .{});
        return;
    };

    try s.beginObject();
    var it_outer = std.mem.splitScalar(u8, buf, options.sep1);
    while (it_outer.next()) |item| {
        var it_inner = std.mem.splitScalar(u8, item, options.sep2);
        const key = it_inner.first();
        const val = it_inner.rest();

        try s.objectField(key);
        try s.write(val);
    }
    try s.endObject();
}

pub fn @"bool"(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    _ = opts;
    const field_value = @field(instance, field.name);
    try s.objectField(field.json_key);
    if (field_value == 0) try s.write(false) else try s.write(true);
}


const ArrayOptions = struct {
    sep: u8 = ',',
};

pub fn array(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    const options: *const ArrayOptions = blk: {
        if (opts == null) {
            break :blk &.{};
        } else {
            break :blk @ptrCast(opts);
        }
    };

    const value = @field(instance, field.name);
    try s.objectField(field.json_key);

    const buf = slurm.parseCStrZ(value) orelse {
        try s.print("[]", .{});
        return;
    };

    try s.beginArray();
    var it = std.mem.splitScalar(u8, buf, options.sep);
    while (it.next()) |item| {
        try s.write(item);
    }
    try s.endArray();
}

fn Number(comptime T: type) type {
    return struct {
        value: ?T,
        infinite: ?bool = null,
    };
}

pub const NumberOptions = struct {
    zero_is_noval: bool = false,
    flat: bool = false,
};

pub fn numberRaw(s: *Stringify, data: anytype, opts: anytype) !void {
    const T = @TypeOf(data);
    const raw_number = @as(T, data);

    const options: *const NumberOptions = blk: {
        if (opts) |o| break :blk @ptrCast(o);
        break :blk &.{};
    };

    const value: ?T = blk: {
        const has_value = slurm.common.numberHasValue(data);

        if ((options.zero_is_noval and raw_number == 0) or !has_value) {
            break :blk null;
        } else {
            break :blk data;
        }
    };

    switch (options.flat) {
        false => try s.write(Number(T){
            .value = value,
            .infinite = slurm.common.numberIsInfinite(data),
        }),
        true => try s.write(value),
    }
}

pub fn number(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    const field_value = @field(instance, field.name);
    try s.objectField(field.json_key);
    try numberRaw(s, field_value, opts);
}

pub fn numberFlat(s: *Stringify, instance: anytype, field: anytype, _: anytype) !void {
    const opts: ?*const anyopaque = &NumberOptions{ .flat = true };
    return number(s, instance, field, opts);
}

pub fn numberFlatNoValue(s: *Stringify, instance: anytype, field: anytype, _: anytype) !void {
    const opts: ?*const anyopaque = &NumberOptions{ .flat = true, .zero_is_noval = true };
    return number(s, instance, field, opts);
}

pub fn jobMemory(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    const value = instance.memory();
    try s.objectField(field.json_key);
    try numberRaw(s, value, opts);
}

pub fn assocShort(s: *Stringify, assoc: *slurm.db.Association) !void {
    const assoc_short: types.AssociationShort = .{
        .account = assoc.acct,
        .cluster = assoc.cluster,
        .user = assoc.user,
        .partition = assoc.partition,
        .id = assoc.id,
    };
    try s.write(assoc_short);
}

pub fn assocsShort(s: *Stringify, instance: anytype, field: anytype, _: anytype) !void {
    try s.objectField(field.json_key);
    const assoc_list = @field(instance, field.name);

    try s.beginArray();
    if (assoc_list) |assocs| {
        var it = assocs.iter();
        while (it.next()) |item| {
            try assocShort(s, item);
        }
    }
    try s.endArray();
}

pub fn jobMemoryTotal(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    const value = instance.memoryTotal();
    try s.objectField(field.json_key);
    try numberRaw(s, value, opts);
}

pub fn loadResponse(s: *Stringify, instance: anytype, _: anytype, _: anytype) !void {
    try s.beginArray();
    var iter = instance.iter();
    while (iter.next()) |item| {
        try json.write(s, item, null);
    }
    try s.endArray();
}

pub const DefaultOptions = struct {
    number_serializer: types.Serialize = number,
};

pub fn memberDefault(s: *Stringify, instance: anytype, field: anytype, opts: anytype) !void {
    _ = opts;

    const value = @field(instance, field.name);

//  switch (@typeInfo(field.type)) {
//      .int => |info| {
//          switch (info.signedness) {
//              .unsigned => {
//                  try number(s, instance, field, null);
//                  return;
//              },
//              .signed => {},
//          }
//      },
//      else => {},
//  }
    try json.write(s, value, field.json_key);
}

pub fn default(s: *Stringify, instance: anytype, _: anytype, _: anytype) !void {
    try s.write(instance);
}

pub const Field = struct {
    json_key: [:0]const u8,
    name: [:0]const u8,
    @"type": type,
};

pub fn container(s: *Stringify, instance: anytype, _: anytype, typ: anytype) !void {
    std.debug.assert(typ.typ != @TypeOf(undefined));

    try s.beginObject();

    const T = @TypeOf(instance.*);
    const fields = @typeInfo(T).@"struct".fields;
    inline for (fields) |field| {
        const option: types.SlurmType.Option = comptime blk: {
            @setEvalBranchQuota(100000);
            for (typ.options) |opt| {
                if (mem.eql(u8, field.name, opt.name)) break :blk opt;
            }

            break :blk .{
                .name = field.name,
            };
        };

        const f: Field = .{
            .json_key = if (option.new_name) |new_name| new_name else field.name,
            .name = field.name,
            .@"type" = field.type,
        };

        try option.serializer(s, instance, f, option.serializer_args);
    }

    inline for (typ.extra_members) |extra_member| {
        const f: Field = .{
            .json_key = extra_member.name,
            .name = extra_member.name,
            .@"type" = undefined,
        };
        try extra_member.serializer(s, instance, f, extra_member.serializer_args);
    }

    try s.endObject();
}

pub fn list(s: *Stringify, instance: anytype, field: anytype, _: anytype) !void {
    if (@TypeOf(field) == Field) {
        const value = @field(instance, field.name);
        return json.write(s, value, field.json_key);
    }

    const T = @TypeOf(instance);
    const List = comptime types.baseType(T);
    const it: ?*List.Iterator = switch (@typeInfo(T)) {
        .optional => if (instance) |i| i.iter() else null,
        else => instance.iter(),
    };

    try s.beginArray();
    if (it) |i| {
        while (i.next()) |item| {
            try json.write(s, item, null);
        }
    }
    try s.endArray();
}
