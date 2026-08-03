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

//  pub fn getQueueSummary(ctx: *RequestContext) !Response(.object) {
//      const data = try slurm.job.load();
//      var queue_summary: QueueSummary = .empty;
//      const allocator = ctx.arena;

//      var iter = data.iter();
//      while (iter.next()) |job| {
//          const job_brief: JobBriefInfo = .{
//              .id = job.job_id,
//              .state = try job.state.toStr(allocator),
//              .user_name = try util.uidToName(allocator, job.user_id),
//              .account = slurm.parseCStrZ(job.account),
//              .partition = slurm.parseCStrZ(job.partition),
//              .qos = slurm.parseCStrZ(job.qos),
//              .resources = .{
//                  .cpus = job.num_cpus,
//                  .memory = job.memoryTotal(),
//                  .gpus = 1, // TODO
//              },
//          };
//          try queue_summary.append(allocator, job_brief);
//      }
//      return .{ .data = try json(allocator, queue_summary.items) };
//  }
