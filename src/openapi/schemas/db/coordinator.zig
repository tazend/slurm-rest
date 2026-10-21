const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = @import("../../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const Coordinators:      SchemaComponent = .array(Coordinator, .list);

pub const CoordinatorsResponse: SchemaComponent = .{
    .api_type = models.CoordinatorsResponse,
    .properties = [_]Property{
        .{
            .api_name = "data",
            .name = "coordinators",
            .description = "List of Coordinators",
            .ref = Coordinators,
            .serde = .string(.print),
        },
    } ++ openapi.components.BaseResponseProperties,
    .serde = .object(.container),
    .child = Coordinators,
};

pub const Coordinator: SchemaComponent = .{
    .api_type = slurm.db.Coordinator,
    .properties = &.{
        .{
            .name = "name",
            .description = "Name of the Coordinator",
            .serde = .string(.native),
        },
        .{
            .name = "direct",
            .description = "Whether the Coordinator is direct",
            .serde = .boolean(.int),
        },
    },
};
