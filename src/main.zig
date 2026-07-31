const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const api = @import("api.zig");
const api_db = @import("api/db.zig");
const auth = @import("auth.zig");
const models = @import("models.zig");
const route = @import("route.zig");

pub fn main() !void {
    var arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    slurm.init(null);

    var handler: Handler = .{};
    var server = try httpz.Server(*Handler).init(allocator, .{ .address = .all(8000) }, &handler);
    defer server.deinit();
    defer server.stop();

    var router = try server.router(.{});
    std.debug.print("listening http://0.0.0.0:{d}/\n", .{8000});

    var api_routes = router.group("/api", .{
      .dispatcher = Handler.dispatchAuth,
    });
    route.addRoutes(&api_routes, api);

    var db_routes = router.group("/api/db", .{
      .dispatcher = Handler.dispatchAuth,
    });
    route.addRoutes(&db_routes, api_db);

    var api_routes2 = router.group("/api2", .{
      .dispatcher = Handler.dispatchAuth,
    });
    route.addRoutes2(&api_routes2);

    try server.listen();
}

pub const Handler = struct {

    pub fn dispatchAuth(self: *Handler, action: httpz.Action(*Handler), req: *httpz.Request, res: *httpz.Response) !void {
//      auth.setThreadConfig(req) catch |err| {
//          std.debug.print("got validation error\n", .{});
//          try res.json(err, .{});
//          return;
//      };
//      defer auth.clearThreadConfig();
        try action(self, req, res);
    }
};
