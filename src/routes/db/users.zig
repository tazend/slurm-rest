const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const route = @import("../../route.zig");
const RouteMeta = route.RouteMeta;
const RouteData = route.RouteData;
const dump = @import("../../json/Dumper.zig").dump;

pub const routes = &.{
    @"GET /db/users",
    @"GET /db/users/:name",
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
            .ref = openapi.UsersResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = openapi.user.query.FilterMany,
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
            .ref = openapi.UserResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = openapi.user.query.FilterSingle,
            .path = openapi.user.path.NameParameter,
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
