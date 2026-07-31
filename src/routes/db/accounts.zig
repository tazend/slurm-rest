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
    @"GET /db/accounts",
    @"GET /db/accounts/:name",
    @"POST /db/accounts",
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
            .ref = openapi.AccountsResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = query_params.Accounts,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AccountsResponse {
        const resp = try slurm.db.account.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try dump(ctx.arena, resp)};
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
            .ref = openapi.AccountsResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.AccountParameter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AccountsResponse {
        // TODO: Utilize existing query
        var list: *slurm.db.List(slurm.CStr) = .initNoDestroyItems();
        defer list.deinit();
        list.append(ctx.parameters.path.name);

        var assoc_cond: slurm.db.Association.Filter = .{
            .acct_list = list,
        };
        const filter: slurm.db.Account.Filter = .{
            .assoc_cond = &assoc_cond,
        };

        const resp = try slurm.db.account.load(ctx.db_conn, filter);
        defer resp.deinit();
        return .{ .data = try dump(ctx.arena, resp)};
    }
};

pub const @"POST /db/accounts" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Accounts",
        },
        .summary = "Create new Accounts",
        .description = "Create new Accounts in the Database",
        .operationId = "createAccounts",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .requestBody = openapi.Account,
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        std.debug.print("{?s}\n", .{ctx.body.name});
        std.debug.print("{?s}\n", .{ctx.body.organization});
        if (ctx.body.coordinators) |c| {
            var it = c.iter();
            while (it.next()) |item| {
                std.debug.print("coord name: {?s}\n", .{item.name});
            }
        }
        if (ctx.body.assoc_list) |c| {
            var it = c.iter();
            while (it.next()) |item| {
                std.debug.print("user: {?s}\n", .{item.user});
                std.debug.print("account: {?s}\n", .{item.acct});
            }
        }
        std.debug.print("flags: {}\n", .{ctx.body.flags});
        return .{};
    }
};
