const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = @import("../../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const Users: SchemaComponent = .array(User, .list);
pub const UsersResponse = openapi.GenericResponse("Users", "List of Database Users");
pub const UserResponse = openapi.GenericResponse("User", "Database User Information");

pub const User: SchemaComponent = .{
    .api_type = slurm.db.User,
    .properties = &.{
        .{
            .name = "admin_level",
            .description = "Admin Level of the User",
            .serde = .string(.native),
        },
        .{
            .api_name = "assoc_list",
            .name = "associations",
            .description = "List of Associations (Short)",
            .serde = .array(.assocs_short),
            .ref = openapi.AssociationsShort,
        },
//      .{
//          .name = "backfill_usage",
//          .description = "Backfill Usage",
//          .serde = .object(.container),
//      },
        .{
            .api_name = "coord_accts",
            .name = "coordinators",
            .description = "List of Coordinators",
            .serde = .array(.list),
            .ref = openapi.Coordinators,
        },
        .{
            .api_name = "def_qos_id",
            .name = "default_qos",
            .description = "Name of the Default QoS",
            .serde = .integer(.native),
        },
        .{
            .api_name = "default_acct",
            .name = "default_account",
            .description = "Default Account",
            .serde = .string(.native),
        },
        .{
            .name = "default_wckey",
            .description = "Default WCKey",
            .serde = .string(.native),
        },
        .{
            .name = "flags",
            .description = "User Flags",
            .serde = .array(.bitflag),
        },
        .{
            .name = "name",
            .description = "Name of the User",
            .serde = .string(.native),
        },
        .{
            .name = "old_name",
            .description = "Old name of the User",
            .serde = .string(.native),
        },
        .{
            .name = "uid",
            .description = "UID of the User",
            .serde = .integer(.native),
        },
        .{
            .api_name = "wckey_list",
            .name = "wckeys",
            .description = "List of WCKeys",
            .serde = .array(.list),
            .ref = openapi.WCKeys,
        },
    },
};

