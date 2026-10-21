const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const route = @import("../../route.zig");
const RouteMeta = route.RouteMeta;
const RouteData = route.RouteData;
const dump = @import("../../json/Dumper.zig").dump;

const components = openapi.components.user;

pub const routes = &.{
    @"GET /db/users",
    @"GET /db/users/:name",
    @"POST /db/users",
};

pub const @"GET /db/users" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Users",
        },
        .summary = "Get Database Users",
        .description = "Get all Users in the Database",
        .operationId = "getUsers",
        .response = .{
            .ref = components.UsersResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = components.query.FilterMany,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.UsersResponse {
        const resp = try slurm.db.user.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try dump(ctx.arena, resp, openapi.Users)};
    }
};

pub const @"GET /db/users/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Users",
        },
        .summary = "Get Database User",
        .description = "Get one User in the Database",
        .operationId = "getUser",
        .response = .{
            .ref = components.UserResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = components.query.FilterSingle,
            .path = components.path.NameParameter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.UserResponse {
        // TODO: make sure to free all lists
        const names_filter = try ctx.pathIdToFilter("names", openapi.user.query.FilterMany);
        var filter = ctx.parameters.query;
        filter.assoc_cond = names_filter.assoc_cond;

        const resp = try slurm.db.user.load(ctx.db_conn, filter);
        defer resp.deinit();

        var iter = resp.iter();
        defer iter.deinit();

        const user = iter.next() orelse return .{ .data = "null" };

        return .{ .data = try ctx.dumpData(user)};
    }
};

pub const @"POST /db/users" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Users",
        },
        .summary = "Modify Database Users",
        .description = "Modify a set of Users in the Database",
        .operationId = "modifyUsers",
        .response = .{
            .ref = openapi.components.BaseResponse,
            .description = "TODO",
        },
        .requestBody = components.UsersUpdatable,
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        var it = ctx.body.iter();
        defer it.deinit();
        while (it.next()) |item| {
            std.debug.print("defacct: {?s}\n", .{item.default_acct});
            std.debug.print("name: {?s}\n", .{item.name});
            std.debug.print("admin_level: {s}\n", .{@tagName(item.admin_level)});
        }
        return .{};
    }
};
