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
    @"GET /partitions",
    @"GET /partitions/:name",
    @"POST /partitions",
};

pub const @"GET /partitions" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Partitions",
        },
        .summary = "Get Partitions",
        .description = "Get all Partitions in the system",
        .operationId = "getPartitions",
        .response = .{
            .ref = openapi.PartitionsResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.PartitionsResponse {
        const resp = try slurm.partition.load();
        defer resp.deinit();
        return .{
            .partitions = try dump(ctx.arena, resp),
            .last_update = resp.last_update,
        };
    }
};

pub const @"GET /partitions/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Partitions",
        },
        .summary = "Get Partition",
        .description = "Get one specific Partition",
        .operationId = "getNode",
        .response = .{
            .ref = openapi.PartitionResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.Partition,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.PartitionResponse {
        const resp = try slurm.partition.load();
        defer resp.deinit();
        const part = resp.find(ctx.parameters.path.name) orelse return slurm.Error.InvalidPartitionName;
        return .{ .data = try dump(ctx.arena, part) };
    }
};

pub const @"POST /partitions" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Partitions",
        },
        .summary = "Update Partitions",
        .description = "Updates Partitions",
        .operationId = "updatePartitions",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .requestBody = openapi.Partition,
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        std.debug.print("name: {?s}\n", .{ctx.body.name});
//      std.debug.print("state: {d}\n", .{@as(u32, @bitCast(ctx.body.state))});
//      std.debug.print("flags: {}\n", .{ctx.body.state.flags});
//      std.debug.print("state all: {}\n", .{ctx.body.state});
        const data = try dump(ctx.arena, ctx.body);
        std.debug.print("{s}\n", .{data});
//        try slurm.node.update(ctx.body);
        return .{};
    }
};
