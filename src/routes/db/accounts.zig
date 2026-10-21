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

const components = openapi.components.account;

pub const routes = &.{
    @"GET /db/accounts",
    @"GET /db/accounts/:name",
    @"POST /db/accounts/:name",
    @"DELETE /db/accounts/:name",
};

pub const @"GET /db/accounts" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Accounts",
        },
        .summary = "Get Database Accounts",
        .description = "Get all Accounts in the Database",
        .operationId = "getAccounts",
        .response = .{
            .ref = components.AccountsResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = components.query.Accounts,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AccountsResponse {
        std.debug.print("query_params: {any}\n", .{ctx.parameters.query});
        var it = ctx.parameters.query.organization_list.?.iter();
        while (it.next()) |i| {
            std.debug.print("org: {s}\n", .{i});
        }

        if (ctx.parameters.query.assoc_cond) |ac| {
            var it2 = ac.acct_list.?.iter();
            while (it2.next()) |i| {
                std.debug.print("name: {s}\n", .{i});
            }
        }
        const resp = try slurm.db.account.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try ctx.dumpData(resp)};
    }
};

pub const @"GET /db/accounts/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Accounts",
        },
        .summary = "Get Database Account",
        .description = "Get one Account in the Database",
        .operationId = "getAccount",
        .response = .{
            .ref = components.AccountResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = components.path.NameParameter,
            .query = components.query.FilterSingle,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AccountSingleResponse {
        // TODO: make sure to free all lists
        var names_filter = try ctx.pathIdToFilter("names", components.query.Accounts);
        names_filter.flags = ctx.parameters.query.flags;

        const resp = try slurm.db.account.load(ctx.db_conn, names_filter);
        defer resp.deinit();

        var iter = resp.iter();
        defer iter.deinit();

        const account = iter.next() orelse return error.UnknownAccount;
        return .{ .data = try ctx.dumpData(account)};
    }
};

pub const @"POST /db/accounts/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Accounts",
        },
        .summary = "Update Account",
        .description = "Update one Account in the Database",
        .operationId = "updateAccount",
        .response = .{
            .ref = openapi.components.BaseResponse,
            .description = "TODO",
        },
        .requestBody = components.AccountUpdatable,
        .parameters = .{
            .path = components.path.NameParameter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        // TODO: make sure to free all lists
        var filter = try ctx.pathIdToFilter("names", components.query.Accounts);

        const data = try dump(ctx.arena, ctx.body, components.AccountUpdatable);
        std.debug.print("{s}\n", .{data});
        // TODO: Error on invalid account
        _ = try slurm.db.account.modify(ctx.db_conn, &filter, &ctx.body);
        try ctx.db_conn.commit();
        return .{};
    }
};

pub const @"DELETE /db/accounts/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Accounts",
        },
        .summary = "Delete Account",
        .description = "Delete Account in the Database",
        .operationId = "deleteAccount",
        .response = .{
            .ref = openapi.components.BaseResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = components.path.NameParameter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        // TODO: make sure to free all lists
        var filter = try ctx.pathIdToFilter("names", components.query.Accounts);

        _ = try slurm.db.account.remove(ctx.db_conn, &filter);
        try ctx.db_conn.commit();
        return .{};
    }
};
