const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../openapi.zig");
const models = @import("../models.zig");
const RouteMeta = @import("../route.zig").RouteMeta;
const RouteData = @import("../route.zig").RouteData;
const SlurmRequirements = @import("../route.zig").SlurmRequirements;
const dump = @import("../json/Dumper.zig").dump;

pub const routes = &.{
    @"GET /diag",
    @"POST /reconfigure",
};

pub const @"GET /diag" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "slurmctld",
        },
        .summary = "Get Controller Diagnostics",
        .description = "Get Controller Diagnostics",
        .operationId = "getSlurmctldDiag",
        .response = .{
            .ref = openapi.ControllerStatisticsResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.ControllerStatisticsResponse {
        const stats = try slurm.slurmctld.loadStats();
        defer stats.deinit();
        return .{ .statistics = try dump(ctx.arena, stats) };
    }
};

pub const @"POST /reconfigure" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "slurmctld",
        },
        .summary = "Reconfigure slurmctld",
        .description = "Perform a reconfigure operation on the slurmctld",
        .operationId = "reconfigureSlurmctld",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
    };

    pub fn handle(_: *const RouteData(@This())) !models.BaseResponse {
        try slurm.slurmctld.reconfigure();
        return .{};
    }
};
