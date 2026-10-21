const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = openapi.models;
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const AssociationsShort: SchemaComponent = .array(AssociationShort, .assocs_short);
pub const Associations:      SchemaComponent = .array(Association, .list);
pub const AssociationsResponse = openapi.GenericResponse(Associations, "List of Associations");
pub const AssociationResponse = openapi.GenericResponse(Association, "Database Association Information");

pub const AssociationShort: SchemaComponent = .{
    .api_type = models.AssociationShort,
    .properties = CommonIdentifier ++ [_]Property{
        .{
            .name = "account",
            .description = "Name of the Account",
            .serde = .string(.native),
        },
    },
    .serde = .object(.container),
};

const CommonIdentifier: []const Property = &.{
    .{
        .name = "cluster",
        .description = "Name of the Cluster",
        .serde = .string(.native),
    },
    .{
        .name = "partition",
        .description = "Name of the Partition",
        .serde = .string(.native),
    },
    .{
        .name = "user",
        .description = "Name of the User, if applicable",
        .serde = .string(.native),
    },
    .{
        .name = "id",
        .description = "ID of the Association",
        .serde = .integer(.native),
    },
};

pub const Identifier: []const Property = CommonIdentifier ++ [_]Property{
    .{
        .api_name = "acct",
        .name = "account",
        .description = "Name of the Account",
        .serde = .string(.native),
    },
};

pub const Limits: []const Property = &.{
    .{
        .api_name = "grp_jobs",
        .name = "group_jobs",
        .description = "Group Job Limit",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "grp_jobs_accrue",
        .name = "group_jobs_accrue",
        .description = "Group Job Accrue",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "grp_submit_jobs",
        .name = "group_submit_jobs",
        .description = "Group Submit Jobs",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "grp_tres",
        .name = "group_tres",
        .description = "Group TRES",
        .serde = .dict(.key_value, &.{ .string, .integer }),
    },
    .{
        .api_name = "grp_tres_mins",
        .name = "group_tres_minutes",
        .description = "Group TRES Minutes",
        .serde = .dict(.key_value, &.{ .integer }),
    },
    .{
        .api_name = "grp_tres_run_mins",
        .name = "group_tres_run_minutes",
        .description = "Group TRES Run Minutes",
        .serde = .dict(.key_value, &.{ .integer }),
    },
    .{
        .api_name = "grp_wall",
        .name = "group_walltime",
        .description = "Group Walltime",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_jobs",
        .name = "max_jobs_total",
        .description = "Max Jobs Total",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .name = "max_jobs_accrue",
        .description = "Max Jobs Accrue",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .name = "max_submit_jobs",
        .description = "Max Jobs submit",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_tres_mins_pj",
        .name = "max_tres_minutes_per_job",
        .description = "Max tres minutes per Job",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_tres_run_mins",
        .name = "max_tres_run_minutes",
        .description = "Max tres run minutes",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_tres_pj",
        .name = "max_tres_per_job",
        .description = "Max tres per Job",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_tres_pn",
        .name = "max_tres_per_node",
        .description = "Max tres per Node",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_wall_pj",
        .name = "max_walltime_per_job",
        .description = "Max Walltime per Job",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "min_prio_thresh",
        .name = "min_priority_threshold",
        .description = "Minimum priority threshold",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "shares_raw",
        .name = "shares",
        .description = "Association Shares",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .name = "priority",
        .description = "Priority",
        .serde = .integer(.native_infinite_is_null),
    },
};

const ReadOnlyProperties: []const Property =
    Identifier
    ++ [_]Property{
//      .{
//          .api_name = "bf_usage",
//          .name = "backfill_usage",
//          .description = "Backfill Usage",
//          .serde = .object(.container),
//      },
    .{
        .name = "flags",
        .description = "Association Flags",
        .serde = .array(.bitflag),
    },
//      .{
//          .name = "leaf_usage",
//          .description = "Leaf Usage",
//          .serde = .object(.container),
//      },
    .{
        .name = "lineage",
        .description = "Association Lineage",
        .serde = .string(.native),
    },
    .{
        .name = "parent_id",
        .description = "Parent Association ID",
        .serde = .integer(.native),
    },
    // TODO: Support List of Strings
//      .{
//          .name = "qos_list",
//          .description = "List of QoS the Association can use",
//          .serde = .array(.list),
//      },
    .{
        .name = "uid",
        .description = "User ID",
        .serde = .integer(.native),
    },
};

pub const AssociationUpdatable: []const Property = Limits ++ [_]Property{
    .{
        .name = "comment",
        .description = "Arbitrary Comment",
        .serde = .string(.native),
    },
    .{
        .api_name = "parent_acct",
        .name = "parent_account",
        .description = "Parent Account",
        .serde = .string(.native),
    },
    .{
        .api_name = "is_def",
        .name = "is_default",
        .description = "Whether this is the Users default Association",
        .serde = .boolean(.int),
    },
};

const IgnoredMembers: []const []const u8 = &.{
        "assoc_next", "assoc_next_id", "user_rec", "accounting_list",
        "max_tres_mins_ctld", "max_tres_run_mins_ctld", "max_tres_ctld",
        "max_tres_pn_ctld", "grp_tres_ctld", "grp_tres_mins_ctld",
        "grp_tres_run_mins_ctld", "usage", "leaf_usage",
};

pub const Association: SchemaComponent = .{
    .api_type = slurm.db.Association,
    .ignored_fields = IgnoredMembers,
    .properties = ReadOnlyProperties ++ AssociationUpdatable,
};

pub const query = struct {

    pub const Flags: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Association.Flags,
        .parameters = &.{
            .{
                .api_name = "with_deleted",
                .name = "with_deleted",
                .description = "Whether to also show deleted Associations",
                .parser = .flags,
            },
            .{
                .api_name = "with_usage",
                .name = "with_usage",
                .description = "Whether to also include Usage",
                .parser = .flags,
            },
            .{
                .api_name = "only_defs",
                .name = "only_defaults",
                .description = "Whether to only show default Associations",
                .parser = .flags,
            },
            .{
                .api_name = "raw_qos",
                .name = "raw_qos",
                .description = "Include raw QoS",
                .parser = .flags,
            },
            .{
                .api_name = "sub_accts",
                .name = "sub_account",
                .description = "Include Sub Account Information",
                .parser = .flags,
            },
            .{
                .api_name = "wopi",
                .name = "without_parent_id",
                .description = "Exclude Parent ID",
                .parser = .flags,
            },
            .{
                .api_name = "wopl",
                .name = "without_parent_limits",
                .description = "Exclude Limits from Parents",
                .parser = .flags,
            },
            .{
                .api_name = "qos_usage",
                .name = "with_qos_usage",
                .description = "Include QoS Usage",
                .parser = .flags,
            },
        },
    };

    pub const FilterSingle: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Association.Filter,
        .refs = &.{
            .{
                .name = "flags",
                .component = Flags,
            },
        },
    };

    pub const FilterMany: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.Association.Filter,
        .refs = &.{
            .{
                .name = "flags",
                .component = Flags,
            },
        },
        .parameters = &.{
            .{
                .api_name = "acct_list",
                .name = "accounts",
                .description = "Accounts to filter for",
                .parser = .list,
            },
            .{
                .api_name = "cluster_list",
                .name = "clusters",
                .description = "Clusters to filter for",
                .parser = .list,
            },
            .{
                .api_name = "def_qos_id_list",
                .name = "default_qos",
                .description = "Default QoS to filter for",
                .parser = .list,
            },
            .{
                .api_name = "id_list",
                .name = "ids",
                .description = "Association IDs to filter for",
                .parser = .list,
            },
            .{
                .api_name = "parent_acct_list",
                .name = "parent_accounts",
                .description = "Parent Accounts to filter for",
                .parser = .list,
            },
            .{
                .api_name = "partition_list",
                .name = "partitions",
                .description = "Partitions to filter for",
                .parser = .list,
            },
            .{
                .api_name = "qos_list",
                .name = "qos",
                .description = "QoS to filter for",
                .parser = .list_qos_ids,
            },
            .{
                .api_name = "user_list",
                .name = "users",
                .description = "Users to filter for",
                .parser = .list,
            },
        },
    };
};

pub const path = struct {
    pub const IDParameter: openapi.PathParameterComponent = .{
        .api_type = models.IDPathParameter([]const u8),
        .parameters = &.{
            .{
                .name = "id",
                .description = "ID of the Association to operate on",
                .type = .string,
            },
        },
    };
};
