const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

const AccountBaseProperties: []const Property = &.{
    .{
        .name = "description",
        .description = "Account description",
        .serde = .string(.native),
    },
    .{
        .name = "flags",
        .description = "Account flags",
        .serde = .array(.bitflag),
    },
    .{
        .name = "name",
        .description = "Name of the Account",
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
        .ref = openapi.Coordinator,
    },
};

pub const Account: SchemaComponent = .{
    .api_type = slurm.db.Account,
    .properties = AccountBaseProperties ++ OtherAccountProperties,
};

pub const Accounts: SchemaComponent = .array(Account, .list);
pub const Response = openapi.GenericResponse("Accounts", "List of Accounts");
