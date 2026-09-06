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
//      std.debug.print("state: {d}\n", .{@as(u32, @bitCast(ctx.body.state))});
//      std.debug.print("flags: {}\n", .{ctx.body.state.flags});
//      std.debug.print("state all: {}\n", .{ctx.body.state});
        const data = try dump(ctx.arena, ctx.body);
        std.debug.print("{s}\n", .{data});
        try slurm.node.update(ctx.body);
        return .{};
    }
};
