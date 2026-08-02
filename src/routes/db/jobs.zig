const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const route = @import("../../route.zig");
const RouteMeta = route.RouteMeta;
const RouteData = route.RouteData;
const SlurmRequirements = route.SlurmRequirements;
const dump = @import("../../json/Dumper.zig").dump;

const query_params = @import("../../query_params.zig");
const path_params = @import("../../openapi/parameters/path.zig");

pub const routes = &.{
    @"GET /db/jobs",
    @"GET /db/jobs/:id",
};

pub const @"GET /db/jobs" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
            "Database",
        },
        .summary = "Get Database Jobs",
        .description = "Get all Jobs in the Database",
        .operationId = "getDBJobs",
        .response = .{
            .ref = openapi.DBJobsResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = query_params.Jobs,
        },
        .requirements = .{
            .db_conn = true,
        },
    };

    pub fn handle(ctx: *RouteData(@This())) !models.DBJobsResponse {
        slurm.c.slurmdb_job_cond_def_start_end(&ctx.parameters.query);
        const jobs = try slurm.db.job.load(ctx.db_conn, ctx.parameters.query);
        defer jobs.deinit();
        return .{ .data = try dump(ctx.arena, jobs)};
    }
};

pub const @"GET /db/jobs/:id" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Jobs",
            "Database",
        },
        .summary = "Get Database Job",
        .description = "Get one Job in the Database",
        .operationId = "getDBJob",
        .response = .{
            .ref = openapi.DBJobResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.JobIDPathParameter,
            .query = query_params.Job,
        },
        .requirements = .{
            .db_conn = true,
        },
    };

    pub fn handle(ctx: *RouteData(@This())) !models.DBJobResponse {
        slurm.c.slurmdb_job_cond_def_start_end(&ctx.parameters.query);
        const job = try slurm.db.job.loadOneWithFilter(ctx.db_conn, ctx.parameters.path.id, ctx.parameters.query);
        defer job.deinit();
        return .{ .data = try dump(ctx.arena, job)};
    }
};
