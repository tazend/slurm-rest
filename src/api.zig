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
