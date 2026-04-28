const std = @import("std");
const Allocator = std.mem.Allocator;
const uid_t = std.posix.uid_t;
const allocPrint = std.fmt.allocPrint;

pub fn uidToName(allocator: Allocator, uid: uid_t) ![]const u8 {
    const passwd_info = std.c.getpwuid(uid);
    if (passwd_info) |pwd| {
        if (pwd.name) |name| {
            const pwd_name = std.mem.span(name);
            return try allocator.dupe(u8, pwd_name);
        }
    }
    return try allocPrint(allocator, "{d}", .{uid});
}
