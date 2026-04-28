const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const api = @import("api.zig");
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
//      .middlewares = &.{cors_middleware},
    });

    api_routes.get("/partitions/:name", route.handler(api.getPartition), .{});
    api_routes.get("/partitions", route.handler(api.getPartitions), .{});
    api_routes.get("/nodes/:name", route.handler(api.getNode), .{});
    api_routes.get("/nodes", route.handler(api.getNodes), .{});
    api_routes.get("/jobs/:id/script", route.handler(api.getJobScript), .{});
    api_routes.get("/jobs/:id", route.handler(api.getJob), .{});
    api_routes.delete("/jobs/:id", route.handler(api.deleteJob), .{});
    api_routes.get("/jobs", route.handler(api.getJobs), .{});
    api_routes.get("/queue", route.handler(api.getQueueSummary), .{});
    api_routes.get("/reservations", route.handler(api.Reservation.get), .{});
    api_routes.get("/reservations/:name", route.handler(api.Reservation.getOne), .{});
    api_routes.get("/slurmctld/diag", route.handler(api.SlurmController.diag), .{});
    api_routes.get("/slurmctld/reconfigure", route.handler(api.SlurmController.reconfigure), .{});

    api_routes.get("/db/users", route.handler(api.DatabaseUsers.get), .{});

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
