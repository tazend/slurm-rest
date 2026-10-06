const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = @import("../../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const WCKeys: SchemaComponent = .array(WCKey, .list);
pub const WCKeysResponse = openapi.GenericResponse("WCKeys", "List of Database WCKeys");

pub const WCKey: SchemaComponent = .{
    .api_type = slurm.db.WCKey,
    .properties = &.{
        // TODO:
        .{
            .name = "accounting_list",
            .description = "Accounting Informations",
            .serde = .noop(),
        },
        .{
            .name = "cluster",
            .description = "Name of the Cluster",
            .serde = .string(.native),
        },
        .{
            .name = "flags",
            .description = "WCKey Flags",
            .serde = .integer(.native),
        },
        .{
            .name = "id",
            .description = "ID",
            .serde = .integer(.native),
        },
        .{
            .name = "is_def",
            .description = "Whether the WCKey is default",
            .serde = .boolean(.int),
        },
        .{
            .name = "name",
            .description = "Name of the WCKey",
            .serde = .string(.native),
        },
        .{
            .name = "uid",
            .description = "UID of the User this WCKey is assigned to",
            .serde = .integer(.native),
        },
        .{
            .name = "user",
            .description = "Name of the User this WCKey is assigned to",
            .serde = .string(.native),
        },
    },
};
