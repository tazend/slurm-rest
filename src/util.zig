const std = @import("std");
const Allocator = std.mem.Allocator;
const uid_t = std.posix.uid_t;
const slurm = @import("slurm");
const allocPrint = std.fmt.allocPrint;

pub fn uidToName(allocator: Allocator, uid: uid_t) !?[]const u8 {
    var buf: [std.c.NAME_MAX]u8 = undefined;
    const name = try uidToNameBuf(&buf, uid) orelse return null;
    return try allocator.dupe(u8, name);
}

pub fn uidToNameBuf(buf: *[std.c.NAME_MAX]u8, uid: uid_t) !?[]const u8 {
    if (!slurm.common.numberHasValue(uid)) {
        return null;
    }
    if (std.c.getpwuid(uid)) |pwd| {
        if (pwd.name) |name| {
            const pwd_name = std.mem.span(name);
            return std.fmt.bufPrint(buf, "{s}", .{pwd_name}) catch error.WriteFailed;
        }
    }
    return std.fmt.bufPrint(buf, "{d}", .{uid}) catch error.WriteFailed;
}
