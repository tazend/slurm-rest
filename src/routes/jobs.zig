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

const JobsParameters = @import("../openapi/parameters/path.zig").DBJobsParameters;

pub const routes = &.{
    @"GET /jobs",
    @"GET /jobs/:id",
    @"DELETE /jobs/:id",
};

pub const @"GET /jobs" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
        },
        .summary = "Get Jobs",
        .description = "Get all Jobs in the System",
        .operationId = "getJobs",
        .response = .{
            .ref = openapi.JobsResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.JobsResponse {
        const resp = try slurm.job.load();
        defer resp.deinit();
        return .{
            .jobs = try dump(ctx.arena, resp),
            .last_backfill = resp.last_backfill,
            .last_update = resp.last_update,
        };
    }
};

pub const @"GET /jobs/:id" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
        },
        .summary = "Get Job",
        .description = "Get a single Job by ID",
        .operationId = "getJob",
        .response = .{
            .ref = openapi.JobResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = JobsParameters,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.JobResponse {
        std.debug.print("job id is: {d}\n", .{ctx.parameters.path.id});
        var job = try slurm.job.loadOne(ctx.parameters.path.id);
        defer job.deinit();
        return .{ .data = try dump(ctx.arena, &job) };
    }
};

pub const @"DELETE /jobs/:id" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
        },
        .summary = "Delete Job",
        .description = "Delete a single Job by ID",
        .operationId = "deleteJob",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = JobsParameters,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        _ = try slurm.job.cancel(ctx.parameters.path.id);
        return .{};
    }
};
