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
    @"GET /db/associations",
    @"GET /db/associations/:id",
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
            .query = openapi.assoc.query.FilterMany,
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
            .query = openapi.assoc.query.FilterSingle,
            .path = openapi.assoc.path.IDParameter,
        },
        .requirements = .{
            .db_conn = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.AssociationResponse {
        // TODO: make sure to free all lists
        var names_filter = try ctx.pathIdToFilter("ids", openapi.assoc.query.FilterMany);
        names_filter.flags = ctx.parameters.query.flags;

        const resp = try slurm.db.association.load(ctx.db_conn, names_filter);
        defer resp.deinit();

        var iter = resp.iter();
        defer iter.deinit();

        const assoc = iter.next() orelse return .{ .data = "null" };

        return .{ .data = try ctx.dumpData(assoc)};
    }
};
