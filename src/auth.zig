const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");

extern fn auth_g_thread_config(token: ?slurm.common.CStr, user_name: ?slurm.common.CStr) c_int;
extern fn auth_g_thread_clear() void;

fn extractBearerToken(auth_header: []const u8) AuthValidationError![]const u8 {
    const prefix = "Bearer ";
    if (std.mem.startsWith(u8, auth_header, prefix)) {
        return auth_header[prefix.len..];
    } else {
        return error.MissingToken;
    }
}

pub const AuthValidationError = error{AmbigousContext, MissingToken, OutOfMemory};

pub fn setThreadConfig(req: *httpz.Request) AuthValidationError!void {
    const key = req.header("x-slurm-user-token");
    const bearer = req.header("authorization");
    const user_name = req.header("x-slurm-user-name");

    if (key != null and bearer != null) {
        return error.AmbigousContext;
    }

    const token = if (key) |k|
        try req.arena.dupeZ(u8, k)
    else if (bearer) |b|
        try req.arena.dupeZ(u8, try extractBearerToken(b))
    else
        return error.MissingToken;

    const u_name: ?slurm.common.CStr = if (user_name) |u|
        try req.arena.dupeZ(u8, u)
    else
        null;

    std.debug.print("token is: {s}\n", .{token});
    std.debug.print("user is: {?s}\n", .{u_name});
    const rc = auth_g_thread_config(token, u_name);
    _ = rc;
}

pub fn clearThreadConfig() void {
    auth_g_thread_clear();
}
