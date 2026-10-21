const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = openapi.models;
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const Users: SchemaComponent = .array(User, .list);
pub const UsersUpdatable: SchemaComponent = .array(UserUpdatable, .list);
pub const UsersResponse = openapi.GenericResponse(Users, "List of Database Users");
pub const UserResponse = openapi.GenericResponse(User, "Database User Information");

pub const UserUpdatable: SchemaComponent = .{
    .api_type = slurm.db.User,
    .properties = &.{
        .{
            .api_name = "default_acct",
            .name = "default_account",
            .description = "Default Account",
            .serde = .string(.native),
        },
        .{
            .name = "name",
            .description = "Name of the User",
            .serde = .string(.native),
        },
        .{
            .name = "admin_level",
            .description = "Admin Level of the User",
            .serde = .string(.@"enum"),
        },
    },
};

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
            .ref = openapi.components.assoc.AssociationsShort,
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
            .ref = openapi.components.coordinator.Coordinators,
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
            .ref = openapi.components.wckey.WCKeys,
        },
    },
};

pub const query = struct {

    const FlagsParameters: []const openapi.QueryParameterComponent.Parameter = &.{
        .{
            .api_name = "with_assocs",
            .name = "with_associations",
            .description = "Include Association Infos",
            .parser = .flags_int,
        },
        .{
            .api_name = "with_coords",
            .name = "with_coordinators",
            .description = "Include Coordinator Infos",
            .parser = .flags_int,
        },
        .{
            .name = "with_deleted",
            .description = "Include deleted Users",
            .parser = .flags_int,
        },
        .{
            .name = "with_wckeys",
            .description = "Include WCKeys",
            .parser = .flags_int,
        },
        .{
            .name = "without_defaults",
            .description = "Exclude Defaults",
            .parser = .flags_int,
        },
    };

    pub const AssocFilter: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Association.Filter,
        .parameters = &.{
            .{
                .api_name = "user_list",
                .name = "names",
                .description = "Filter for specific User Names",
                .parser = .list,
            },
        },
    };

    pub const FilterSingle: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.User.Filter,
        .parameters = FlagsParameters,
    };

    pub const FilterMany: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.User.Filter,
        .refs = &.{
            .{
                .name = "assoc_cond",
                .component = AssocFilter,
            },
        },
        .parameters = [_]openapi.QueryParameterComponent.Parameter{
            .{
                .name = "admin_level",
                .description = "Admin Level to filter for",
                .parser = .@"enum",
            },
            .{
                .api_name = "def_acct_list",
                .name = "default_accounts",
                .description = "Default Accounts to filter for",
                .parser = .list,
            },
            .{
                .api_name = "def_wckey_list",
                .name = "default_wckeys",
                .description = "Default WCKeys to filter for",
                .parser = .list,
            },
        } ++ FlagsParameters,
    };

};

pub const path = struct {
    pub const NameParameter: openapi.PathParameterComponent = .name("User");
};
