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
    @"POST /nodes",
    @"DELETE /nodes/:name",
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
            .nodes = try ctx.dumpData(resp),
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
        return .{ .data = try ctx.dumpData(&node) };
    }
};

pub const @"POST /nodes" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Nodes",
        },
        .summary = "Update Nodes",
        .description = "Updates Nodes",
        .operationId = "updateNodes",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .requestBody = openapi.NodeUpdatable,
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        const data = try dump(ctx.arena, ctx.body, openapi.NodeUpdatable);
        std.debug.print("{s}\n", .{data});
        //try slurm.node.update(ctx.body);
        return .{};
    }
};

pub const @"DELETE /nodes/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Nodes",
        },
        .summary = "Delete Node",
        .description = "Delete one specific Node",
        .operationId = "deleteNode",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.Node,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        const msg: slurm.Node.Updatable = .{
            .names = ctx.parameters.path.name,
        };
        // TODO: This returns InvalidNodeState if the node cannot be deleted.
        // Catch that and return a better error.
        try slurm.node.delete(msg);
        return .{};
    }
};
