const std = @import("std");
const uidToNameBuf = @import("../util.zig").uidToNameBuf;
const mem = std.mem;
const slurm = @import("slurm");
const Stringify = std.json.Stringify;
const json = @import("../json.zig");
const types = json.types;
const Dumper = @import("Dumper.zig");

/// Skips a field / container entirely
pub fn noop(_: *Stringify, _: anytype, _: Dumper.Context) !void {}

const DictOptions = struct {
    sep1: u8 = ',',
    sep2: u8 = '=',
};

pub fn dict(s: *Stringify, value: anytype, ctx: Dumper.Context) !void {
    std.debug.assert(ctx.field != null);

    const options: *const DictOptions = blk: {
        if (ctx.options == null) {
            break :blk &.{};
        } else {
            break :blk @ptrCast(ctx.options.?);
        }
    };

    const field_value = @field(value, ctx.field.?.name);
    try s.objectField(ctx.field.?.json_key);

    const buf = slurm.parseCStrZ(field_value) orelse {
        try s.print("{{}}", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf)) {
        try s.print("{{}}", .{});
        return;
    }

    try s.beginObject();
    var it_outer = std.mem.splitScalar(u8, buf, options.sep1);
    while (it_outer.next()) |item| {
        var it_inner = std.mem.splitScalar(u8, item, options.sep2);
        const key = it_inner.first();
        const val = it_inner.rest();
        const val_num = std.fmt.parseInt(u128, val, 10) catch null;

        try s.objectField(key);
        if (val_num) |v| {
            try s.write(v);
        } else try s.write(val);
    }
    try s.endObject();
}

pub fn @"bool"(s: *Stringify, value: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);

    const field_value = @field(value, field.name);
    try s.objectField(field.json_key);
    if (field_value == 0) try s.write(false) else try s.write(true);
}

pub fn gresDict(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);

    const value = @field(instance, field.name);
    try s.objectField(field.json_key);

    const buf = slurm.parseCStrZ(value) orelse {
        try s.print("{{}}", .{});
        return;
    };

    if (std.mem.eql(u8, "N/A", buf)) {
        try s.print("{{}}", .{});
        return;
    }

    var it = std.mem.splitScalar(u8, buf, ',');
    try s.beginObject();
    while (it.next()) |item| {
        var it_inner = std.mem.splitBackwardsScalar(u8, item, ':');
        const count = it_inner.first();
        const key = it_inner.rest();

        try s.objectField(key);
        try s.write(count);
    }
    try s.endObject();
}

pub fn resCoreSpec(s: *Stringify, instance: *slurm.Reservation, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);

    try s.objectField(field.json_key);
    if (instance.core_spec_cnt == slurm.common.NoValue.u32 or instance.core_spec == null) {
        try s.print("[]", .{});
        return;
    }

    try s.beginArray();
    for (0..instance.core_spec_cnt) |i| {
        const spec = instance.core_spec.?[i];
        const name = slurm.parseCStr(spec.node_name) orelse continue;
        const id = slurm.parseCStr(spec.core_id) orelse continue;

        try s.beginObject();
        try s.objectField("name");
        try s.write(name);
        try s.objectField("id");
        try s.write(id);
        try s.endObject();
    }
    try s.endArray();
}

const ArrayOptions = struct {
    sep: u8 = ',',
    numbers: bool = false,
};

pub fn array(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const options = comptime ctx.getOptions(ArrayOptions);

    const value = @field(instance, field.name);
    try s.objectField(field.json_key);

    const buf = slurm.parseCStrZ(value) orelse {
        try s.print("[]", .{});
        return;
    };

    try s.beginArray();
    var it = std.mem.splitScalar(u8, buf, options.sep);
    while (it.next()) |item| {
        switch (options.numbers) {
            true => {
                const v = std.fmt.parseInt(u64, item, 10) catch continue;
                try s.write(v);
            },
            false => try s.write(item),
        }
    }
    try s.endArray();
}

pub fn arrayInt(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    return array(s, instance, .{
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

pub fn number(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const field_value = @field(instance, field.name);
    try s.objectField(field.json_key);
    try numberRaw(s, field_value, ctx.options);
}

pub fn numberFlat(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    return number(s, instance, .{
        .field = ctx.field,
        .options = &NumberOptions{ .flat = true },
    });
}

pub fn numberFlatNoInfinite(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const field_value = @field(instance, field.name);
    if (slurm.common.numberIsInfinite(field_value)) {
        try s.objectField(field.json_key);
        try s.write(null);
    } else return numberFlat(s, instance, ctx);
}

pub fn numberNoValue(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    return number(s, instance, .{
        .field = ctx.field,
        .options = &NumberOptions{ .zero_is_noval = true },
    });
}

pub fn numberFlatNoValue(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    return number(s, instance, .{
        .field = ctx.field,
        .options = &NumberOptions{ .flat = true, .zero_is_noval = true },
    });
}

pub fn jobMemory(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = instance.memory();
    try s.objectField(field.json_key);
    try numberRaw(s, value, ctx.options);
}

pub fn stepIDString(s: *Stringify, instance: slurm.Step.ID, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    var buf: [128]u8 = undefined;
    const value = instance.toStrBuf(&buf) catch null;
    try s.objectField(field.json_key);
    try s.write(value);
}

fn assocShort(s: *Stringify, assoc: *slurm.db.Association) !void {
    const assoc_short: types.AssociationShort = .{
        .account = assoc.acct,
        .cluster = assoc.cluster,
        .user = assoc.user,
        .partition = assoc.partition,
        .id = assoc.id,
    };
    try s.write(assoc_short);
}

pub fn assocsShort(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
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

pub fn jobMemoryTotal(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = instance.memoryTotal();
    try s.objectField(field.json_key);
    try numberRaw(s, value, ctx.options);
}

pub fn nodeState(s: *Stringify, instance: *const slurm.Node, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const field_value = @field(instance, field.name);
    const state = if (@as(u32, @bitCast(field_value)) != slurm.common.NoValue.u32)
        @tagName(field_value.base)
    else
        null;
    try s.objectField(field.json_key);
    try s.write(state);
}

pub fn nodeIdleCpus(s: *Stringify, instance: *slurm.Node, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const util = instance.utilization();
    try s.objectField(field.json_key);
    try s.write(util.idle_cpus);
}

pub fn userName(comptime field_name: [:0]const u8) Dumper.NewDumpFN {
    const S = struct {
        pub fn parse(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
            const field = ctx.field orelse std.debug.assert(false);
            var buf: [std.c.NAME_MAX]u8 = undefined;
            const value_raw = @field(instance, field_name);
            const value = try uidToNameBuf(&buf, value_raw);
            try s.objectField(field.json_key);
            try s.write(value);
        }
    };
    return &S.parse;
}

pub fn stdio(comptime field_name: [:0]const u8) Dumper.NewDumpFN {
    const S = struct {
        pub fn parse(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
            const field = ctx.field orelse std.debug.assert(false);
            var buf: [std.c.PATH_MAX]u8 = undefined;
            const value = @field(instance, field_name);
            const path = instance.getStdioPath(value, &buf) catch null;
            try s.objectField(field.json_key);
            try s.write(path);
        }
    };
    return &S.parse;
}

pub fn sluid(s: *Stringify, instance: slurm.Step.ID, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    var buf: [15:0]u8 = undefined;
    const value = instance.parseSluid(&buf);
    try s.objectField(field.json_key);
    try s.write(value);
}

pub fn timestampRaw(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = @field(instance, field.name);
    const time = if (value != 0) value else null;
    try s.objectField(field.json_key);
    try s.write(time);
}

pub fn loadResponse(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    std.debug.assert(ctx.schema != null);

    try s.beginArray();
    var iter = instance.iter();
    while (iter.next()) |item| {
        try Dumper.writeRequireSchema(s, item);
    }
    try s.endArray();
}

pub fn memberDefault(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = ctx.field orelse std.debug.assert(false);
    const value = @field(instance, field.name);
    const T = @TypeOf(value);

    if (T == std.posix.time_t) {
        try timestampRaw(s, instance, ctx);
        return;
    }
    try s.objectField(field.json_key);
    try s.write(value);
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

pub fn native(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const value = @field(instance, field.name);
    try s.objectField(field.json_key);
    try s.write(value);
}

pub fn printString(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    const field = comptime ctx.requireField();
    const value = @field(instance, field.name);
    try s.objectField(field.json_key);
    try s.print("{?s}", .{value});
}

pub fn unsupported(_: *Stringify, _: anytype, _: Dumper.Context) !void {
    @compileError("Dumping this Type through this API is not supported");
}

pub fn container(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    if (ctx.field) |f| {
        // TODO: Also support non-optionals?
        const value = @field(instance, f.name);
        try s.objectField(f.json_key);
        return Dumper.writeRequireSchema(s, value);
    }

    const schema = comptime ctx.requireSchema();

    const v = switch (@typeInfo(@TypeOf(instance))) {
        .optional => if (instance) |i| i else return try s.write(null),
        else => instance,
    };

    try s.beginObject();
    inline for (schema.properties) |prop| {
        const f: Dumper.FieldDescription = .{
            .json_key = prop.name,
            .name = prop.api_name orelse prop.name,
        };
        const field_ctx: Dumper.Context = .{
            .field = f,
            .options = null,
        };
        try prop.serde.dump(s, v, field_ctx);
    }
    try s.endObject();
}

pub fn list(s: *Stringify, instance: anytype, ctx: Dumper.Context) !void {
    if (ctx.field) |f| {
        const value = @field(instance, f.name);
        try s.objectField(f.json_key);
        return try Dumper.writeRequireSchema(s, value);
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
            try Dumper.writeRequireSchema(s, item);
        }
    }
    try s.endArray();
}
