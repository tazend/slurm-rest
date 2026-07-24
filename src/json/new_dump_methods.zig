const std = @import("std");
const uidToNameBuf = @import("../util.zig").uidToNameBuf;
const mem = std.mem;
const slurm = @import("slurm");
const Stringify = std.json.Stringify;
const json = @import("../json.zig");
const types = json.types;
const Dumper = @import("Dumper.zig");

/// Skips a field / container entirely
pub fn noop(_: *Dumper, _: anytype, _: Dumper.Context) !void {}

const DictOptions = struct {
    sep1: u8 = ',',
    sep2: u8 = '=',
};

pub fn dict(dumper: *Dumper, value: anytype, ctx: Dumper.Context) !void {
    std.debug.assert(ctx.field != null);

    const options: *const DictOptions = blk: {
        if (ctx.options == null) {
            break :blk &.{};
        } else {
            break :blk @ptrCast(ctx.options.?);
        }
    };

    const field_value = @field(value, ctx.field.?.name);
    try dumper.json.objectField(ctx.field.?.json_key);

    const buf = slurm.parseCStrZ(field_value) orelse {
        try dumper.json.print("{{}}", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf)) {
        try dumper.json.print("{{}}", .{});
        return;
    }

    try dumper.json.beginObject();
    var it_outer = std.mem.splitScalar(u8, buf, options.sep1);
    while (it_outer.next()) |item| {
        var it_inner = std.mem.splitScalar(u8, item, options.sep2);
        const key = it_inner.first();
        const val = it_inner.rest();
        const val_num = std.fmt.parseInt(u128, val, 10) catch null;

        try dumper.json.objectField(key);
        if (val_num) |v| {
            try dumper.json.write(v);
        } else try dumper.json.write(val);
    }
    try dumper.json.endObject();
}

pub fn @"bool"(dumper: *Dumper, value: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);

    const field_value = @field(value, field.name);
    try dumper.json.objectField(field.json_key);
    if (field_value == 0) try dumper.json.write(false) else try dumper.json.write(true);
}

pub fn gresDict(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);

    const value = @field(instance, field.name);
    try dumper.json.objectField(field.json_key);

    const buf = slurm.parseCStrZ(value) orelse {
        try dumper.json.print("{{}}", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf)) {
        try dumper.json.print("{{}}", .{});
        return;
    }

    var it = std.mem.splitScalar(u8, buf, ',');
    try dumper.json.beginObject();
    while (it.next()) |item| {
        var it_inner = std.mem.splitBackwardsScalar(u8, item, ':');
        const count = it_inner.first();
        const key = it_inner.rest();

        try dumper.json.objectField(key);
        try dumper.json.write(count);
    }
    try dumper.json.endObject();
}

pub fn resCoreSpec(dumper: *Dumper, instance: *slurm.Reservation, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);

    try dumper.json.objectField(field.json_key);
    if (instance.core_spec_cnt == slurm.common.NoValue.u32 or instance.core_spec == null) {
        try dumper.json.print("[]", .{});
        return;
    }

    try dumper.json.beginArray();
    for (0..instance.core_spec_cnt) |i| {
        const spec = instance.core_spec.?[i];
        const name = slurm.parseCStr(spec.node_name) orelse continue;
        const id = slurm.parseCStr(spec.core_id) orelse continue;

        try dumper.json.beginObject();
        try dumper.json.objectField("name");
        try dumper.json.write(name);
        try dumper.json.objectField("id");
        try dumper.json.write(id);
        try dumper.json.endObject();
    }
    try dumper.json.endArray();
}

const ArrayOptions = struct {
    sep: u8 = ',',
    numbers: bool = false,
};

pub fn array(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const options = comptime ctx.getOptions(ArrayOptions);

    const value = @field(instance, field.name);
    try dumper.json.objectField(field.json_key);

    const buf = slurm.parseCStrZ(value) orelse {
        try dumper.json.print("[]", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf) or buf.len == 0) {
        try dumper.json.print("[]", .{});
        return;
    }

    try dumper.json.beginArray();
    var it = std.mem.splitScalar(u8, buf, options.sep);
    while (it.next()) |item| {
        switch (options.numbers) {
            true => {
                const v = std.fmt.parseInt(u64, item, 10) catch continue;
                try dumper.json.write(v);
            },
            false => try dumper.json.write(item),
        }
    }
    try dumper.json.endArray();
}

pub fn arrayInt(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    return array(dumper, instance, .{
        .field = ctx.field,
        .options = &ArrayOptions{ .numbers = true },
    });
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

pub fn numberRaw(dumper: *Dumper, data: anytype, opts: anytype) !void {
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
        false => try dumper.json.write(Number(T){
            .value = value,
            .infinite = slurm.common.numberIsInfinite(data),
        }),
        true => try dumper.json.write(value),
    }
}

pub fn number(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const field_value = @field(instance, field.name);
    try dumper.json.objectField(field.json_key);
    try numberRaw(dumper, field_value, ctx.options);
}

pub fn numberFlat(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    return number(dumper, instance, .{
        .field = ctx.field,
        .options = &NumberOptions{ .flat = true },
    });
}

pub fn numberFlatNoInfinite(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const field_value = @field(instance, field.name);
    if (slurm.common.numberIsInfinite(field_value)) {
        try dumper.json.objectField(field.json_key);
        try dumper.json.write(null);
    } else return numberFlat(dumper, instance, ctx);
}

pub fn numberNoValue(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    return number(dumper, instance, .{
        .field = ctx.field,
        .options = &NumberOptions{ .zero_is_noval = true },
    });
}

pub fn numberFlatNoValue(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    return number(dumper, instance, .{
        .field = ctx.field,
        .options = &NumberOptions{ .flat = true, .zero_is_noval = true },
    });
}

pub fn jobMemory(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = instance.memory();
    try dumper.json.objectField(field.json_key);
    try numberRaw(dumper, value, ctx.options);
}

pub fn stepIDString(dumper: *Dumper, instance: slurm.Step.ID, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    var buf: [128]u8 = undefined;
    const value = instance.toStrBuf(&buf) catch null;
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(value);
}

fn assocShort(dumper: *Dumper, assoc: *slurm.db.Association) !void {
    const assoc_short: types.AssociationShort = .{
        .account = assoc.acct,
        .cluster = assoc.cluster,
        .user = assoc.user,
        .partition = assoc.partition,
        .id = assoc.id,
    };
    try dumper.json.write(assoc_short);
}

pub fn assocsShort(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    try dumper.json.objectField(field.json_key);
    const assoc_list = @field(instance, field.name);

    try dumper.json.beginArray();
    if (assoc_list) |assocs| {
        var it = assocs.iter();
        while (it.next()) |item| {
            try assocShort(dumper, item);
        }
    }
    try dumper.json.endArray();
}

pub fn jobMemoryTotal(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = instance.memoryTotal();
    try dumper.json.objectField(field.json_key);
    try numberRaw(dumper, value, ctx.options);
}

pub fn nodeState(dumper: *Dumper, instance: *const slurm.Node, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const field_value = @field(instance, field.name);
    const state = if (@as(u32, @bitCast(field_value)) != slurm.common.NoValue.u32)
        @tagName(field_value.base)
    else
        null;
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(state);
}

pub fn nodeIdleCpus(dumper: *Dumper, instance: *slurm.Node, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const util = instance.utilization();
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(util.idle_cpus);
}

pub fn userName(comptime field_name: [:0]const u8) Dumper.NewDumpFN {
    const S = struct {
        pub fn parse(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
            const field = ctx.field orelse std.debug.assert(false);
            var buf: [std.c.NAME_MAX]u8 = undefined;
            const value_raw = @field(instance, field_name);
            const value = try uidToNameBuf(&buf, value_raw);
            try dumper.json.objectField(field.json_key);
            try dumper.json.write(value);
        }
    };
    return &S.parse;
}

pub fn stdio(comptime field_name: [:0]const u8) Dumper.NewDumpFN {
    const S = struct {
        pub fn parse(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
            const field = ctx.field orelse std.debug.assert(false);
            var buf: [std.c.PATH_MAX]u8 = undefined;
            const value = @field(instance, field_name);
            const path = instance.getStdioPath(value, &buf) catch null;
            try dumper.json.objectField(field.json_key);
            try dumper.json.write(path);
        }
    };
    return &S.parse;
}

pub fn sluid(dumper: *Dumper, instance: slurm.Step.ID, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    var buf: [15:0]u8 = undefined;
    const value = instance.parseSluid(&buf);
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(value);
}

pub fn timestampRaw(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = @field(instance, field.name);
    const time = if (value != 0) value else null;
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(time);
}

pub fn loadResponse(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    std.debug.assert(ctx.schema != null);

    try dumper.json.beginArray();
    var iter = instance.iter();
    while (iter.next()) |item| {
        try Dumper.writeRequireSchema(dumper, item);
    }
    try dumper.json.endArray();
}

pub fn memberDefault(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = @field(instance, field.name);
    const T = @TypeOf(value);

    if (T == std.posix.time_t) {
        try timestampRaw(dumper, instance, ctx);
        return;
    }
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(value);
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
}

pub fn native(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const value = @field(instance, field.name);
    try dumper.json.objectField(field.json_key);
    try dumper.json.write(value);
}

pub fn printString(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const value = @field(instance, field.name);
    try dumper.json.objectField(field.json_key);
    try dumper.json.print("{?s}", .{value});
}

pub fn unsupported(_: *Dumper, _: anytype, _: Dumper.Context) !void {
    @compileError("Dumping this Type through this API is not supported");
}

pub fn container(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    if (ctx.field) |f| {
        // TODO: Also support non-optionals?
        const value = @field(instance, f.name);
        try dumper.json.objectField(f.json_key);
        return Dumper.writeRequireSchema(dumper, value);
    }

    const schema = comptime ctx.requireSchema();

    const v = switch (@typeInfo(@TypeOf(instance))) {
        .optional => if (instance) |i| i else return try dumper.json.write(null),
        else => instance,
    };

    try dumper.json.beginObject();
    inline for (schema.properties) |prop| {
        const f: Dumper.FieldDescription = .{
            .json_key = prop.name,
            .name = prop.api_name orelse prop.name,
        };
        const field_ctx: Dumper.Context = .{
            .field = f,
            .options = null,
        };
        try prop.serde.dump(dumper, v, field_ctx);
    }
    try dumper.json.endObject();
}

pub fn list(dumper: *Dumper, instance: anytype, ctx: Dumper.Context) !void {
    if (ctx.field) |f| {
        const value = @field(instance, f.name);
        try dumper.json.objectField(f.json_key);
        return try Dumper.writeRequireSchema(dumper, value);
    }

    const T = @TypeOf(instance);
    const List = comptime types.baseType(T);
    const it: ?*List.Iterator = switch (@typeInfo(T)) {
        .optional => if (instance) |i| i.iter() else null,
        else => instance.iter(),
    };

    try dumper.json.beginArray();
    if (it) |i| {
        while (i.next()) |item| {
            try Dumper.writeRequireSchema(dumper, item);
        }
    }
    try dumper.json.endArray();
}
