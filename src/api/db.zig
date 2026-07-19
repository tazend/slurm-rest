const std = @import("std");
const slurm = @import("slurm");
const models = @import("../models.zig");
const dump = @import("../json/Dumper.zig").dump;
const RequestContext = @import("../route.zig").RequestContext;

pub fn @"GET /jobs"(ctx: *RequestContext) !models.DBJobsResponse {
    const conn: *slurm.db.Connection = try .open();
    const filter: slurm.db.Job.Filter = .{};
    const jobs = try slurm.db.job.load(conn, filter);
    return .{ .data = try dump(ctx.arena, jobs)};
}

pub fn @"GET /jobs/:id"(ctx: *RequestContext) !models.DBJobResponse {
    const conn: *slurm.db.Connection = try .open();
    const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
    const job = try slurm.db.job.loadOne(conn, id);
    return .{ .data = try dump(ctx.arena, job)};
}

pub fn @"GET /accounts"(ctx: *RequestContext) !models.AccountsResponse {
    const conn: *slurm.db.Connection = try .open();
    const filter: slurm.db.Account.Filter = .{};
    const resp = try slurm.db.account.load(conn, filter);
    return .{ .data = try dump(ctx.arena, resp)};
}

pub fn @"GET /users"(ctx: *RequestContext) !models.UsersResponse {
    const conn: *slurm.db.Connection = try .open();
    var assoc_cond: slurm.db.Association.Filter = .{
        .flags = .{
            .only_defs = true,
        }
    };
    const users = try slurm.db.user.load(conn, .{ .assoc_cond = &assoc_cond, .with_assocs = 1 });
    return .{ .data = try dump(ctx.arena, users)};
}

pub fn @"GET /associations"(ctx: *RequestContext) !models.AssociationsResponse {
    const conn: *slurm.db.Connection = try .open();
    const filter: slurm.db.Association.Filter = .{};
    const resp = try slurm.db.association.load(conn, filter);
    return .{ .data = try dump(ctx.arena, resp)};
}
