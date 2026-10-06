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
const spec = @import("../openapi/spec.zig");

pub const routes = &.{
    @"GET /openapi",
};

pub const @"GET /openapi" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "openapi",
        },
        .summary = "Get the OpenAPI Specification",
        .description = "Get the OpenAPI Specification",
        .operationId = "getOpenAPI",
        .response = .{
            .ref = openapi.SpecificationResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.OpenAPISpecificationResponse {
        return .{
            .spec = try spec.process(ctx.arena),
        };
    }
};
