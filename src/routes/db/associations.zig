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
    @"GET /db/associations",
};

pub const @"GET /db/associations" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Associations",
        },
        .summary = "Get Database Associations",
        .description = "Get all Associations in the Database",
        .operationId = "getAssociations",
        .response = .{
            .ref = openapi.AssociationsResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = query_params.Associations,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AssociationsResponse {
        const resp = try slurm.db.association.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try dump(ctx.arena, resp)};
    }
};
