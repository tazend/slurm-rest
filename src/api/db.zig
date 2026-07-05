const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const jsonx = @import("../json.zig");
const Response = models.Response;
const Handler = @import("../main.zig").Handler;
const models = @import("../models.zig");
const Allocator = std.mem.Allocator;
const json = @import("../api.zig").json;
const RequestContext = @import("../route.zig").RequestContext;

pub const Jobs = struct {

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const conn: *slurm.db.Connection = try .open();
        const filter: slurm.db.Job.Filter = .{};
        const jobs = try slurm.db.job.load(conn, filter);
        return .{ .data = try json(ctx.arena, jobs)};
    }

    pub fn getOne(ctx: *RequestContext) !Response(.object) {
        const conn: *slurm.db.Connection = try .open();
        const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
        const job = try slurm.db.job.loadOne(conn, id);
        return .{ .data = try json(ctx.arena, job)};
    }
};

pub const Accounts = struct {

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const conn: *slurm.db.Connection = try .open();
        const filter: slurm.db.Account.Filter = .{};
        const resp = try slurm.db.account.load(conn, filter);
        return .{ .data = try json(ctx.arena, resp)};
    }
};

pub const Users = struct {

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const conn: *slurm.db.Connection = try .open();
        var assoc_cond: slurm.db.Association.Filter = .{
            .flags = .{
                .only_defs = true,
            }
        };
        const users = try slurm.db.user.load(conn, .{ .assoc_cond = &assoc_cond, .with_assocs = 1 });
        return .{ .data = try json(ctx.arena, users)};
    }
};

pub const Associations = struct {

    pub fn get(ctx: *RequestContext) !Response(.array) {
        const conn: *slurm.db.Connection = try .open();
        const filter: slurm.db.Association.Filter = .{};
        const resp = try slurm.db.association.load(conn, filter);
        return .{ .data = try json(ctx.arena, resp)};
    }
};
