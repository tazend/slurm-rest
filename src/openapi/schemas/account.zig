const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

const AccountUpdatableProperties: []const Property = &.{
    .{
        .name = "description",
        .description = "Account description",
        .serde = .string(.native),
    },
    .{
        .name = "organization",
        .description = "Name of the Organization",
        .serde = .string(.native),
    },
};

const OtherAccountProperties: []const Property = &.{
    .{
        .name = "name",
        .description = "Name of the Account",
        .serde = .string(.native),
    },
    .{
        .name = "flags",
        .description = "Account flags",
        .serde = .array(.bitflag),
    },
    .{
        .api_name = "assoc_list",
        .name = "associations",
        .description = "List of Associations (short-form) for the Account",
        .serde = .array(.assocs_short),
        .ref = openapi.AssociationsShort,
    },
    .{
        .name = "coordinators",
        .description = "List of Coordinators",
        .serde = .array(.list),
        .ref = openapi.Coordinators,
    },
};

pub const AccountUpdatable: SchemaComponent = .{
    .api_type = slurm.db.Account,
    .properties = AccountUpdatableProperties,
};

pub const Account: SchemaComponent = .{
    .api_type = slurm.db.Account,
    .properties = AccountUpdatableProperties ++ OtherAccountProperties,
};

pub const Accounts: SchemaComponent = .array(Account, .list);
pub const Response = openapi.GenericResponse("Accounts", "List of Accounts");
pub const SingleResponse = openapi.GenericResponse("Account", "Database Account Information");

pub const query = struct {
    pub const Accounts: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Account.Filter,
        .refs = &.{
            .{
                .name = "flags",
                .component = AccountFlags,
            },
            .{
                .name = "assoc_cond",
                .component = AccountAssocFilter,
            },
        },
        .parameters = &.{
            .{
                .api_name = "description_list",
                .name = "descriptions",
                .description = "Descriptions to filter for",
                .parser = .list,
            },
            .{
                .api_name = "organization_list",
                .name = "organizations",
                .description = "Organizations to filter for",
                .parser = .list,
            },
        },
    };

    pub const AccountFlags: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Account.Flags,
        .parameters = &.{
            .{
                .api_name = "deleted",
                .name = "with_deleted",
                .description = "Whether to also show deleted Accounts",
                .parser = .flags,
            },
            .{
                .api_name = "with_assocs",
                .name = "with_associations",
                .description = "Whether to also fetch Associations",
                .parser = .flags,
            },
            .{
                .api_name = "with_coords",
                .name = "with_coordinators",
                .description = "Whether to also fetch Coordinators",
                .parser = .flags,
            },
        },
    };

    pub const AccountAssocFilter: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Association.Filter,
        .parameters = &.{
            .{
                .api_name = "acct_list",
                .name = "names",
                .description = "Filter for specific Account Names",
                .parser = .list,
            },
        },
    };

};
