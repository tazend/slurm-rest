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
    @"GET /db/wckeys",
    @"GET /db/wckeys/:id",
};

pub const @"GET /db/wckeys" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "WCKey",
        },
        .summary = "Get Database WCKeys",
        .description = "Get all WCKeys in the Database",
        .operationId = "getWCKeys",
        .response = .{
            .ref = openapi.WCKeysResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = openapi.wckey.query.FilterMany,
        },
        .requirements = .{
            .db_conn = true,
            .tres = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.WCKeysResponse {
        const resp = try slurm.db.wckey.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try ctx.dumpData(resp) };
    }
};

pub const @"GET /db/wckeys/:id" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "WCKey",
        },
        .summary = "Get Database WCKey",
        .description = "Get one WCKey in the Database",
        .operationId = "getWCKey",
        .response = .{
            .ref = openapi.WCKeyResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = openapi.wckey.path.IDParameter,
            .query = openapi.wckey.query.FilterSingle,
        },
        .requirements = .{
            .db_conn = true,
            .tres = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.WCKeyResponse {
        const names_filter = try ctx.pathIdToFilter("id", openapi.wckey.query.FilterMany);
        var filter = ctx.parameters.query;
        filter.id_list = names_filter.id_list;

        const resp = try slurm.db.wckey.load(ctx.db_conn, filter);
        defer resp.deinit();

        var iter = resp.iter();
        defer iter.deinit();

        const wckey = iter.next() orelse return .{ .data = "null" };

        return .{ .data = try ctx.dumpData(wckey)};
    }
};
