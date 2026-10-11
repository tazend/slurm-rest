const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const route = @import("../../route.zig");
const RouteMeta = route.RouteMeta;
const RouteData = route.RouteData;
const dump = @import("../../json/Dumper.zig").dump;

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
            .query = openapi.assoc.query.Filter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AssociationsResponse {
        const resp = try slurm.db.association.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try ctx.dumpData(resp)};
    }
};

pub const @"GET /db/associations/:id" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Associations",
        },
        .summary = "Get Database Association",
        .description = "Get one Association in the Database",
        .operationId = "getAssociation",
        .response = .{
            .ref = openapi.assoc.AssociationResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = openapi.assoc.query.Filter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AssociationResponse {
        const resp = try slurm.db.association.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try ctx.dumpData(resp)};
    }
};
