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
    @"GET /db/qos",
    @"GET /db/qos/:name",
};

pub const @"GET /db/qos" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "QoS",
        },
        .summary = "Get Database QoS",
        .description = "Get all QoS in the Database",
        .operationId = "getQoS",
        .response = .{
            .ref = openapi.QoSResponse,
            .description = "TODO",
        },
        .parameters = .{
            .query = openapi.qos.query.Filter,
        },
        .requirements = .{
            .db_conn = true,
            .tres = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.QoSResponse {
        const resp = try slurm.db.qos.load(ctx.db_conn, ctx.parameters.query);
        defer resp.deinit();
        return .{ .data = try dump(ctx.arena, resp, openapi.QoSArray)};
    }
};

pub const @"GET /db/qos/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "QoS",
        },
        .summary = "Get single Database QoS",
        .description = "Get single QoS in the Database",
        .operationId = "getOneQoS",
        .response = .{
            .ref = openapi.QoSSingleResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.QoS,
            .query = openapi.qos.query.Flags,
        },
        .requirements = .{
            .db_conn = true,
            .tres = true,
        }
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.QoSSingleResponse {
        var filter = try ctx.pathIdToFilter("names", openapi.qos.query.Filter);
        filter.flags = ctx.parameters.query;

        const resp = try slurm.db.qos.load(ctx.db_conn, filter);
        defer resp.deinit();

        var iter = resp.iter();
        defer iter.deinit();

        const qos = iter.next() orelse return .{ .data = "null" };

        return .{ .data = try ctx.dumpData(qos)};
    }
};
