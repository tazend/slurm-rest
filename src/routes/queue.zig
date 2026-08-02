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
    @"GET /queue",
};

pub const @"GET /queue" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
        },
        .summary = "Get Queue Summary",
        .description = "Get a small Summary of the current Job Queue",
        .operationId = "getJobQueue",
        .response = .{
            .ref = openapi.ReservationsResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.ReservationsResponse {
        _ = ctx;
    }
};
