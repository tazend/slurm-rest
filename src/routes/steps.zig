const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../openapi.zig");
const models = @import("../models.zig");
const RequestContext = @import("../route.zig").RequestContext;
const RouteMeta = @import("../route.zig").RouteMeta;
const RouteData = @import("../route.zig").RouteData;
const SlurmRequirements = @import("../route.zig").SlurmRequirements;
const dump = @import("../json/Dumper.zig").dump;

pub const routes = &.{
    @"GET /steps",
};

pub const @"GET /steps" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
            "Steps",
        },
        .summary = "Get Job Steps",
        .description = "Get all Job steps in the system",
        .operationId = "getJobSteps",
        .response = .{
            .ref = openapi.StepsResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.StepsResponse {
        const resp = try slurm.step.load();
        defer resp.deinit();
        return .{
            .steps = try dump(ctx.arena, resp),
            .last_update = resp.last_update,
        };
    }
};
