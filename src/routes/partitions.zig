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
    @"POST /partitions/:name",
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
            .partitions = try ctx.dumpData(resp),
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
        return .{ .data = try ctx.dumpData(part) };
    }
};

pub const @"POST /partitions/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Partitions",
        },
        .summary = "Update Partition",
        .description = "Update a single Partition",
        .operationId = "updatePartition",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .requestBody = openapi.part.Updatable,
        .parameters = .{
            .path = path_params.Partition,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        var part = ctx.body;
        part.name = ctx.parameters.path.name;
        const data = try dump(ctx.arena, part, openapi.Partition);
        std.debug.print("{s}\n", .{data});
        try slurm.partition.update(part);
        return .{};
    }
};
