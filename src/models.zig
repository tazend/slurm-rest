const std = @import("std");
const mem = std.mem;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const json = @import("json.zig");

pub const APIError = error{} || slurm.err.Error;

pub const Error = struct {
    name: [:0]const u8,
    description: []const u8,
};

pub const SlurmVersion = struct {
    major: u32,
    minor: u32,
    micro: u32,
};

pub const SlurmMeta = struct {
    cluster: ?[]const u8 = null,
    release: ?[]const u8 = null,
    version: SlurmVersion,
};

pub const Meta = struct {
    slurm: ?SlurmMeta = null,
};

pub fn Response(comptime T: json.Type) type {
    return struct {
        @"error": ?Error = null,
        meta: ?Meta = null,
        data: ?[]const u8 = DefaultValue,
        @"type": json.Type = T,

        pub const DefaultValue = switch(T) {
            .array => "[]",
            .string => "",
            .object => "{}",
            .null => null,
            else => unreachable,
        };

        pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
            try jw.beginObject();
            try jw.objectField("error");
            try jw.write(self.@"error");
            try jw.objectField("meta");
            try jw.write(self.meta);

            try jw.objectField("data");
            try jw.print("{?s}", .{self.data});
            try jw.endObject();
        }
    };
}
