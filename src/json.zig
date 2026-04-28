const std = @import("std");
const Allocator = std.mem.Allocator;
const Stringify = std.json.Stringify;

pub const types = @import("json/types.zig");
pub const ser = @import("json/parse.zig");

pub const Type = enum {
    object,
    string,
    number,
    integer,
    boolean,
    array,
    null,
};

pub fn fmt(value: anytype, options: Stringify.Options) Formatter(@TypeOf(value)) {
    return Formatter(@TypeOf(value)){ .value = value, .options = options };
}

pub fn write(s: *Stringify, value: anytype, key: ?[]const u8) std.Io.Writer.Error!void {
    const tdef = comptime types.find(@TypeOf(value));

    if (key) |k| {
        if (tdef.serializer == ser.noop) return;
        try s.objectField(k);
    }

    try tdef.serializer(s, value, null, tdef);
}

pub fn serialize(value: anytype, options: Stringify.Options, writer: *std.Io.Writer) !void {
    var s: Stringify = .{ .writer = writer, .options = options };
    try write(&s, value, null);
}

pub fn stringify(allocator: Allocator, value: anytype, options: Stringify.Options) ![]const u8 {
    return try std.fmt.allocPrint(allocator, "{f}", .{fmt(value, options)});
}

/// Formats the given value using stringify.
pub fn Formatter(comptime T: type) type {
    return struct {
        value: T,
        options: Stringify.Options,

        pub fn format(self: @This(), writer: *std.Io.Writer) std.Io.Writer.Error!void {
            try serialize(self.value, self.options, writer);
        }
    };
}
