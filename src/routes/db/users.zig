const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const route = @import("../../route.zig");
const RouteMeta = route.RouteMeta;
const RouteData = route.RouteData;
const dump = @import("../../json/Dumper.zig").dump;

const query_params = @import("../../query_params.zig");
const path_params = @import("../../openapi/parameters/path.zig");

pub const routes = &.{
    @"GET /db/users",
};

pub const @"GET /db/users" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Accounts",
        },
        .summary = "Get Database Accounts",
        .description = "Get all Accounts in the Database",
        .operationId = "getAccounts",
        .response = .{
            .ref = openapi.UsersResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = query_params.Users,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.UsersResponse {
        const resp = try slurm.db.user.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try dump(ctx.arena, resp)};
    }
};
