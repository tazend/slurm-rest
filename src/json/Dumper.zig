const std = @import("std");
const Allocator = std.mem.Allocator;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const Dumper = @This();
const openapi = @import("../openapi.zig");
const models = @import("../models.zig");
const SerdeContext = @import("SerdeContext.zig");

pub const NewDumpFN = *const fn(dumper: *Dumper, value: anytype, ctx: Dumper.Context) anyerror!void;

json: Stringify,
allocator: Allocator,

pub const Context = struct {
    field: ?FieldDescription = null,
    options: ?*const anyopaque = null,
    schema: ?openapi.SchemaComponent = null,

    pub fn getOptions(self: Context, comptime T: type) T {
        if (self.options) |o| {
            const p: *T = @ptrCast(@constCast(o));
            return p.*;
        } else return .{};
    }

    pub fn require(self: Context, name: [:0]const u8) baseType(@TypeOf(@field(self, name))) {
        const value = @field(self, name);
        return if (value) |v|
            v
        else
            @compileError("Missing context requirement: " ++ name);
    }

    pub fn requireField(self: Context) FieldDescription {
        return self.require("field");
    }

    pub fn requireSchema(self: Context) openapi.SchemaComponent {
        return self.require("schema");
    }
};

pub const FieldDescription = struct {
    json_key: [:0]const u8,
    name: [:0]const u8,
};

pub fn writeRequireSchema(dumper: *Dumper, value: anytype) !void {
    const T = @TypeOf(value);
    const schema = comptime getSchema(T);
    const ctx: Context = .{
        .schema = schema,
        .field = null,
        .options = null,
    };
    try schema.serde.dump(dumper, value, ctx);
}

pub fn init(allocator: Allocator, writer: *std.Io.Writer) Dumper {
    return .{
        .allocator = allocator,
        .json = .{
            .options = .{},
            .writer = writer,
        },
    };
}

pub fn dump(allocator: Allocator, value: anytype) ![]const u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    var dumper: Dumper = .init(allocator, &aw.writer);
    try writeRequireSchema(&dumper, value);
    return aw.toOwnedSlice();
}

pub fn getSchema(comptime T: type) openapi.SchemaComponent {
    const decls = @typeInfo(openapi).@"struct".decls;
    const Child = comptime baseType(T);

    for (decls) |decl| {
        const field = @field(openapi, decl.name);
        if (@TypeOf(field) == openapi.SchemaComponent) {
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

test {
    slurm.init(null);
//    const item = try slurm.node.load();
    const item = try slurm.job.load();
//    const item = try slurm.reservation.load();
//    const item = try slurm.partition.load();

    const bla = try dump(std.heap.page_allocator, item);
    const r: models.JobsResponse = .{ .jobs = bla, .last_backfill = 0, .last_update = 0 };
    //const r: models.PartitionArrayResponse = .{ .partitions = bla, .last_update = 0 };
    const r_dump = try dump(std.heap.page_allocator, r);
    std.debug.print("{s}", .{r_dump});
}
