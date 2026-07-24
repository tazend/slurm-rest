const std = @import("std");
const slurm = @import("slurm");
const models = @import("../models.zig");
const dump = @import("../json/Dumper.zig").dump;
const parse = @import("../json/Parser.zig").parse;
const RequestContext = @import("../route.zig").RequestContext;
const query_params = @import("../query_params.zig");

pub fn @"GET /jobs"(ctx: *RequestContext) !models.DBJobsResponse {
    const conn: *slurm.db.Connection = try .open();
    var filter = try query_params.parse(query_params.Jobs, ctx);
    // NOTE: Maybe we don't really need this?
    slurm.c.slurmdb_job_cond_def_start_end(&filter);
    const jobs = try slurm.db.job.load(conn, filter);
    defer jobs.deinit();
    return .{ .data = try dump(ctx.arena, jobs)};
}

pub fn @"GET /jobs/:id"(ctx: *RequestContext) !models.DBJobResponse {
    const conn: *slurm.db.Connection = try .open();
    const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
    var filter = try query_params.parse(query_params.Job, ctx);
    slurm.c.slurmdb_job_cond_def_start_end(&filter);
    const job = try slurm.db.job.loadOneWithFilter(conn, id, filter);
    defer job.deinit();
    return .{ .data = try dump(ctx.arena, job)};
}

pub fn @"GET /jobs/:id/script"(ctx: *RequestContext) !models.DBJobResponse {
    const conn: *slurm.db.Connection = try .open();
    const id = try std.fmt.parseInt(u32, ctx.req.param("id").?, 10);
    var filter = try query_params.parse(query_params.Job, ctx);
    slurm.c.slurmdb_job_cond_def_start_end(&filter);
    const job = try slurm.db.job.loadOneWithFilter(conn, id, filter);
    defer job.deinit();

    const script = if (slurm.parseCStr(job.script)) |s|
        try ctx.arena.dupe(u8, s)
    else
        null;
    return .{ .data = script };
}

pub fn @"GET /accounts"(ctx: *RequestContext) !models.AccountsResponse {
    const conn: *slurm.db.Connection = try .open();
    const filter = try query_params.parse(query_params.Accounts, ctx);
    const resp = try slurm.db.account.load(conn, filter);
    defer resp.deinit();
    return .{ .data = try dump(ctx.arena, resp)};
}

pub fn @"POST /accounts"(ctx: *RequestContext) !models.BaseResponse {
    const conn: *slurm.db.Connection = try .open();
    const t = try parse(slurm.db.Account, ctx.arena, ctx.req.body() orelse return error.EmptyBody);
    std.debug.print("{?s}\n", .{t.name});
    std.debug.print("{?s}\n", .{t.organization});
    if (t.coordinators) |c| {
        var it = c.iter();
        while (it.next()) |item| {
            std.debug.print("coord name: {?s}\n", .{item.name});
        }
    }
    if (t.assoc_list) |c| {
        var it = c.iter();
        while (it.next()) |item| {
            std.debug.print("user: {?s}\n", .{item.user});
            std.debug.print("account: {?s}\n", .{item.acct});
        }
    }
    std.debug.print("flags: {}\n", .{t.flags});
    _ = conn;
    return .{};
}

pub fn @"GET /accounts/:name"(ctx: *RequestContext) !models.AccountsResponse {
    const conn: *slurm.db.Connection = try .open();
    const name = ctx.req.param("name").?;
    const name_z = try ctx.arena.dupeZ(u8, name);

    var list: *slurm.db.List(slurm.CStr) = .initNoDestroyItems();
    defer list.deinit();
    list.append(name_z);

    var assoc_cond: slurm.db.Association.Filter = .{
        .acct_list = list,
    };
    const filter: slurm.db.Account.Filter = .{
        .assoc_cond = &assoc_cond,
    };

    const resp = try slurm.db.account.load(conn, filter);
    defer resp.deinit();
    return .{ .data = try dump(ctx.arena, resp)};
}

pub fn @"GET /users"(ctx: *RequestContext) !models.UsersResponse {
    const conn: *slurm.db.Connection = try .open();
    const filter = try query_params.parse(query_params.Users, ctx);
    const users = try slurm.db.user.load(conn, filter);
    defer users.deinit();
    return .{ .data = try dump(ctx.arena, users)};
}

pub fn @"GET /associations"(ctx: *RequestContext) !models.AssociationsResponse {
    const conn: *slurm.db.Connection = try .open();
    const filter = try query_params.parse(query_params.Associations, ctx);
    const resp = try slurm.db.association.load(conn, filter);
    defer resp.deinit();
    return .{ .data = try dump(ctx.arena, resp)};
}
