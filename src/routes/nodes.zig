const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../openapi.zig");
const models = @import("../models.zig");
const RequestContext = @import("../route.zig").RequestContext;
const RouteMeta = @import("../route.zig").RouteMeta;
const RouteData = @import("../route.zig").RouteData;
const SlurmRequirements = @import("../route.zig").SlurmRequirements;
const dump = @import("../json/Dumper.zig").dump;

const path_params = @import("../openapi/parameters/path.zig");

pub const routes = &.{
    @"GET /nodes",
    @"GET /nodes/:name",
};

pub const @"GET /nodes" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Nodes",
        },
        .summary = "Get Nodes",
        .description = "Get all Nodes in the system",
        .operationId = "getNodes",
        .response = .{
            .ref = openapi.NodesResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.NodesResponse {
        const resp = try slurm.node.load();
        defer resp.deinit();
        return .{
            .nodes = try dump(ctx.arena, resp),
            .last_update = resp.last_update,
        };
    }
};

pub const @"GET /nodes/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Nodes",
        },
        .summary = "Get Node",
        .description = "Get one specific Node",
        .operationId = "getNode",
        .response = .{
            .ref = openapi.NodeResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.Node,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.NodeResponse {
        var node = try slurm.node.loadOne(ctx.parameters.path.name);
        defer node.deinit();
        return .{ .data = try dump(ctx.arena, &node) };
    }
};
