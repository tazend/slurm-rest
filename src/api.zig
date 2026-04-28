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

pub fn getQueueSummary(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.object) {
    const data = try slurm.job.load();
    var queue_summary: QueueSummary = .empty;
    const allocator = res.arena;

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
    return .{ .data = try json(res.arena, queue_summary.items) };
}

pub fn deleteJob(_: *Handler, req: *httpz.Request, _: *httpz.Response) !Response(.null) {
    const id = try std.fmt.parseInt(u32, req.param("id").?, 10);
    _ = try slurm.job.cancel(id);
    return .{};
}

pub fn getJobs(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.array) {
    const resp = try slurm.job.load();
    defer resp.deinit();
    return .{ .data = try json(res.arena, resp), };
}

pub fn getJob(_: *Handler, req: *httpz.Request, res: *httpz.Response) !Response(.object) {
    const id = req.param("id").?;
    var job = try slurm.job.loadOne(try std.fmt.parseInt(u32, id, 10));
    defer job.deinit();
    return .{ .data = try json(res.arena, &job) };
}

pub fn getJobScript(_: *Handler, req: *httpz.Request, res: *httpz.Response) !Response(.string) {
    const id = try std.fmt.parseInt(u32, req.param("id").?, 10);
    return .{ .data = try slurm.job.getBatchScript(res.arena, id) };
}

pub fn getNodes(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.array) {
    const resp = try slurm.node.load();
    defer resp.deinit();
    return .{ .data = try json(res.arena, resp) };
}

pub fn getNode(_: *Handler, req: *httpz.Request, res: *httpz.Response) !Response(.object) {
    const name = req.param("name").?;
    const name_z = try res.arena.dupeZ(u8, name);
    var node = try slurm.node.loadOne(name_z);
    defer node.deinit();
    return .{ .data = try json(res.arena, &node) };
}

pub fn getPartitions(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.array) {
    const resp = try slurm.partition.load();
    defer resp.deinit();
    return .{ .data = try json(res.arena, resp) };
}

pub fn getPartition(_: *Handler, req: *httpz.Request, res: *httpz.Response) !Response(.object) {
    const name = req.param("name").?;

    const resp = try slurm.partition.load();
    defer resp.deinit();

    var iter = resp.iter();
    while (iter.next()) |part| {
        const part_name = slurm.parseCStrZ(part.name) orelse continue;
        if (std.mem.eql(u8, name, part_name)) {
            return .{ .data = try json(res.arena, part) };
        }
    }
    return slurm.Error.InvalidPartitionName;
}

pub const Reservation = struct {

    pub fn get(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.array) {
        const resp = try slurm.reservation.load();
        defer resp.deinit();
        return .{ .data = try json(res.arena, resp) };
    }

    pub fn getOne(_: *Handler, req: *httpz.Request, res: *httpz.Response) !Response(.object) {
        const name = req.param("name").?;

        const resp = try slurm.reservation.load();
        defer resp.deinit();

        var iter = resp.iter();
        while (iter.next()) |resv| {
            const resv_name = slurm.parseCStrZ(resv.name) orelse continue;
            if (std.mem.eql(u8, name, resv_name)) {
                return .{ .data = try json(res.arena, resv) };
            }
        }
        return slurm.Error.ReservationInvalid;
    }
};

pub const SlurmController = struct {

    pub fn diag(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.object) {
        const stats = try slurm.slurmctld.loadStats();
        defer stats.deinit();
        return .{ .data = try json(res.arena, stats) };
    }

    pub fn reconfigure(_: *Handler, _: *httpz.Request, _: *httpz.Response) !Response(.null) {
        try slurm.slurmctld.reconfigure();
        return .{};
    }
};

pub const DatabaseUsers = struct {

    pub fn get(_: *Handler, _: *httpz.Request, res: *httpz.Response) !Response(.array) {
        const conn: *slurm.db.Connection = try .open();
        var assoc_cond: slurm.db.Association.Filter = .{
            .flags = .{
                .only_defs = true,
            }
        };
        const users = try slurm.db.user.load(conn, .{ .assoc_cond = &assoc_cond, .with_assocs = 1 });
        return .{ .data = try json(res.arena, users)};
    }
};

inline fn json(arena: Allocator, value: anytype) ![]const u8 {
    return jsonx.stringify(arena, value, .{});
}
