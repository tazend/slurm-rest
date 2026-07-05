const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const Allocator = std.mem.Allocator;
const uid_t = std.posix.uid_t;
const allocPrint = std.fmt.allocPrint;
const Handler = @import("main.zig").Handler;
const models = @import("models.zig");
const jsonx = @import("json.zig");
const Response = models.Response;
const util = @import("util.zig");
const RequestContext = @import("route.zig").RequestContext;

pub const db = @import("api/db.zig");

const JobBriefInfo = struct {
    id: u32,
    state: ?[]const u8 = null,
    user_name: ?[]const u8 = null,
    account: ?[:0]const u8 = null,
    partition: ?[:0]const u8 = null,
    qos: ?[:0]const u8 = null,
    resources: ?Resources = null,

    const Resources = struct {
        cpus: u32,
        memory: u64,
        gpus: u32,
    };
};

const QueueSummary = std.ArrayListUnmanaged(JobBriefInfo);

pub fn getQueueSummary(ctx: *RequestContext) !Response(.object) {
    const data = try slurm.job.load();
    var queue_summary: QueueSummary = .empty;
    const allocator = ctx.arena;

    var iter = data.iter();
    while (iter.next()) |job| {
        const job_brief: JobBriefInfo = .{
            .id = job.job_id,
            .state = try job.state.toStr(allocator),
            .user_name = try util.uidToName(allocator, job.user_id),
            .account = slurm.parseCStrZ(job.account),
            .partition = slurm.parseCStrZ(job.partition),
            .qos = slurm.parseCStrZ(job.qos),
            .resources = .{
                .cpus = job.num_cpus,
                .memory = job.memoryTotal(),
                .gpus = 1, // TODO
            },
        };
        try queue_summary.append(allocator, job_brief);
    }
    return .{ .data = try json(allocator, queue_summary.items) };
}

pub const Job = struct {

    pub fn getSteps(ctx: *RequestContext) !Response(.array) {
        const id = ctx.req.param("id").?;
        const resp = try slurm.step.loadForJob(try std.fmt.parseInt(u32, id, 10));
        defer resp.deinit();
        return .{ .data = try json(ctx.arena, resp) };
    }

    pub fn getOne(ctx: *RequestContext) !Response(.object) {
        const id = ctx.req.param("id").?;
        var job = try slurm.job.loadOne(try std.fmt.parseInt(u32, id, 10));
        defer job.deinit();
        return .{ .data = try json(ctx.arena, &job) };
    }

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const resp = try slurm.job.load();
        defer resp.deinit();
        return .{ .data = try json(ctx.arena, resp), };
    }

    pub fn delete(ctx: *RequestContext) !Response(.null) {
        const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
        _ = try slurm.job.cancel(id);
        return .{};
    }

    pub fn getScript(ctx: *RequestContext) !Response(.string) {
        const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
        const script = try slurm.job.getBatchScript(ctx.arena, id);
        return .{ .data = try json(ctx.arena, script) };
    }
};

pub const Step = struct {

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const resp = try slurm.step.load();
        defer resp.deinit();
        return .{ .data = try json(ctx.arena, resp), };
    }
};

pub fn getNodes(ctx: *RequestContext) !Response(.array) {
    const resp = try slurm.node.load();
    defer resp.deinit();
    return .{ .data = try json(ctx.arena, resp) };
}

pub fn getNode(ctx: *RequestContext) !Response(.object) {
    const name = ctx.req.param("name").?;
    const name_z = try ctx.arena.dupeZ(u8, name);
    var node = try slurm.node.loadOne(name_z);
    defer node.deinit();
    return .{ .data = try json(ctx.arena, &node) };
}

pub fn getPartitions(ctx: *RequestContext) !Response(.array) {
    const resp = try slurm.partition.load();
    defer resp.deinit();
    return .{ .data = try json(ctx.arena, resp) };
}

pub fn getPartition(ctx: *RequestContext) !Response(.object) {
    const name = ctx.req.param("name").?;

    const resp = try slurm.partition.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |part| {
        const part_name = slurm.parseCStrZ(part.name) orelse continue;
        if (std.mem.eql(u8, name, part_name)) {
            return .{ .data = try json(ctx.arena, part) };
        }
    }
    return slurm.Error.InvalidPartitionName;
}

pub const Reservation = struct {

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const resp = try slurm.reservation.load();
        defer resp.deinit();
        return .{ .data = try json(ctx.arena, resp) };
    }

    pub fn getOne(ctx: *RequestContext) !Response(.object) {
        const name = ctx.req.param("name").?;

        const resp = try slurm.reservation.load();
        defer resp.deinit();

        var iter = resp.iter();
        while (iter.next()) |resv| {
            const resv_name = slurm.parseCStrZ(resv.name) orelse continue;
            if (std.mem.eql(u8, name, resv_name)) {
                return .{ .data = try json(ctx.arena, resv) };
            }
        }
        return slurm.Error.ReservationInvalid;
    }
};

pub const SlurmController = struct {

    pub fn diag(ctx: *RequestContext) !Response(.object) {
        const stats = try slurm.slurmctld.loadStats();
        defer stats.deinit();
        return .{ .data = try json(ctx.arena, stats) };
    }

    pub fn reconfigure(_: *RequestContext) !Response(.null) {
        try slurm.slurmctld.reconfigure();
        return .{};
    }
};

pub inline fn json(arena: Allocator, value: anytype) ![]const u8 {
    return jsonx.stringify(arena, value, .{});
}
