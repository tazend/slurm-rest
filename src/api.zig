const std = @import("std");
const slurm = @import("slurm");
const models = @import("models.zig");
const util = @import("util.zig");
const RequestContext = @import("route.zig").RequestContext;
const JobBriefInfo = models.JobBriefInfo;
const dump = @import("json/Dumper.zig").dump;

//const QueueSummary = models.QueueSummary;

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

pub fn @"GET /jobs/:id/steps"(ctx: *RequestContext) !models.StepsResponse {
    const id = ctx.req.param("id").?;
    const resp = try slurm.step.loadForJob(try std.fmt.parseInt(u32, id, 10));
    defer resp.deinit();
    return .{
        .steps = try dump(ctx.arena, resp) ,
        .last_update = resp.last_update,
    };
}

pub fn @"GET /jobs/:id"(ctx: *RequestContext) !models.JobResponse {
    const id = ctx.req.param("id").?;
    var job = try slurm.job.loadOne(try std.fmt.parseInt(u32, id, 10));
    defer job.deinit();
    return .{ .data = try dump(ctx.arena, &job) };
}

pub fn @"GET /jobs"(ctx: *RequestContext) !models.JobsResponse {
    const resp = try slurm.job.load();
    defer resp.deinit();
    return .{
        .jobs = try dump(ctx.arena, resp),
        .last_backfill = resp.last_backfill,
        .last_update = resp.last_update,
    };
}

//  pub fn @"DELETE /jobs/:id"(ctx: *RequestContext) !models.BaseResponse {
//      const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
//      _ = try slurm.job.cancel(id);
//      return .{};
//  }

pub fn @"GET /jobs/:id/script"(ctx: *RequestContext) !models.JobScriptResponse {
    const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
    const script = try slurm.job.getBatchScript(ctx.arena, id);
    return .{ .script = script };
}

pub fn @"GET /steps"(ctx: *RequestContext) !models.StepsResponse {
    const resp = try slurm.step.load();
    defer resp.deinit();
    return .{
        .steps = try dump(ctx.arena, resp),
        .last_update = resp.last_update,
    };
}

pub fn @"GET /nodes"(ctx: *RequestContext) !models.NodesResponse {
    const resp = try slurm.node.load();
    defer resp.deinit();
    return .{ .nodes = try dump(ctx.arena, resp) };
}

pub fn @"GET /nodes/:name"(ctx: *RequestContext) !models.NodeResponse {
    const name = ctx.req.param("name").?;
    const name_z = try ctx.arena.dupeZ(u8, name);
    var node = try slurm.node.loadOne(name_z);
    defer node.deinit();
    return .{ .data = try dump(ctx.arena, &node) };
}

pub fn @"GET /partitions"(ctx: *RequestContext) !models.PartitionsResponse {
    const resp = try slurm.partition.load();
    defer resp.deinit();
    return .{
        .partitions = try dump(ctx.arena, resp),
        .last_update = resp.last_update,
    };
}

pub fn @"GET /partitions/:name"(ctx: *RequestContext) !models.PartitionResponse {
    const name = ctx.req.param("name").?;

    const resp = try slurm.partition.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |part| {
        const part_name = slurm.parseCStrZ(part.name) orelse continue;
        if (std.mem.eql(u8, name, part_name)) {
            return .{ .data = try dump(ctx.arena, part) };
        }
    }
    return slurm.Error.InvalidPartitionName;
}

pub fn @"GET /reservations"(ctx: *RequestContext) !models.ReservationsResponse {
    const resp = try slurm.reservation.load();
    defer resp.deinit();
    return .{
        .reservations = try dump(ctx.arena, resp),
        .last_update = resp.last_update,
    };
}

pub fn @"GET /reservations/:name"(ctx: *RequestContext) !models.ReservationResponse {
    const name = ctx.req.param("name").?;

    const resp = try slurm.reservation.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |resv| {
        const resv_name = slurm.parseCStrZ(resv.name) orelse continue;
        if (std.mem.eql(u8, name, resv_name)) {
            return .{ .data = try dump(ctx.arena, resv) };
        }
    }
    return slurm.Error.ReservationInvalid;
}

//  pub const SlurmController = struct {

//      pub fn diag(ctx: *RequestContext) !Response(.object) {
//          const stats = try slurm.slurmctld.loadStats();
//          defer stats.deinit();
//          return .{ .data = try json(ctx.arena, stats) };
//      }

//      pub fn reconfigure(_: *RequestContext) !Response(.null) {
//          try slurm.slurmctld.reconfigure();
//          return .{};
//      }
//  };
