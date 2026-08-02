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

const JobsParameters = @import("../openapi/parameters/path.zig").JobIDPathParameter;

pub const routes = &.{
    @"GET /jobs",
    @"GET /jobs/:id",
    @"GET /jobs/:id/steps",
    @"GET /jobs/:id/script",
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
        var job = try slurm.job.loadOne(ctx.parameters.path.id);
        defer job.deinit();
        return .{ .data = try dump(ctx.arena, &job) };
    }
};

pub const @"GET /jobs/:id/steps" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
        },
        .summary = "Get Steps for a Job",
        .description = "Get all Steps for a single Job",
        .operationId = "getJobSteps",
        .response = .{
            .ref = openapi.StepsResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = JobsParameters,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.StepsResponse {
        const resp = try slurm.step.loadForJob(ctx.parameters.path.id);
        defer resp.deinit();
        return .{
            .steps = try dump(ctx.arena, resp),
            .last_update = resp.last_update,
        };
    }
};

pub const @"GET /jobs/:id/script" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
        },
        .summary = "Get batch script",
        .description = "Get batch script for a Job",
        .operationId = "getJobScript",
        .response = .{
            .ref = openapi.JobScriptResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = JobsParameters,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.JobScriptResponse {
        const script = try slurm.job.getBatchScript(ctx.arena, ctx.parameters.path.id);
        return .{ .script = script };
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
