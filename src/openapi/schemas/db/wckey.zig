const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = openapi.models;
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const WCKeys: SchemaComponent = .array(WCKey, .list);

pub const WCKeyResponse: SchemaComponent = .{
    .api_type = models.WCKeyResponse,
    .properties = [_]Property{
        .{
            .api_name = "data",
            .name = "steps",
            .description = "WCKey Information",
            .ref = WCKey,
            .serde = .string(.print),
        },
    } ++ openapi.components.BaseResponseProperties,
    .serde = .object(.container),
    .child = WCKey,
};

pub const WCKeysResponse: SchemaComponent = .{
    .api_type = models.WCKeysResponse,
    .properties = [_]Property{
        .{
            .api_name = "data",
            .name = "steps",
            .description = "List of WCKeys",
            .ref = WCKeys,
            .serde = .string(.print),
        },
    } ++ openapi.components.BaseResponseProperties,
    .serde = .object(.container),
    .child = WCKeys,
};

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

pub const query = struct {
    pub const FlagsParameters: []const openapi.QueryParameterComponent.Parameter = &.{
        .{
            .name = "with_deleted",
            .description = "Whether to also show deleted WCKeys",
            .parser = .flags_int,
        },
        .{
            .name = "with_usage",
            .description = "Whether to also fetch WCKey Usage",
            .parser = .flags_int,
        },
    };

    pub const FilterSingle: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.WCKey.Filter,
        .parameters = FlagsParameters,
    };

    pub const FilterMany: openapi.QueryParameterComponent = .{
        .api_type = slurm.db.WCKey.Filter,
        .parameters = [_]openapi.QueryParameterComponent.Parameter{
            .{
                .api_name = "cluster_list",
                .name = "cluster",
                .description = "Cluster to filter for",
                .parser = .list,
            },
            .{
                .api_name = "id_list",
                .name = "id",
                .description = "ID to filter for",
                .parser = .list,
            },
            .{
                .api_name = "name_list",
                .name = "name",
                .description = "Name to filter for",
                .parser = .list,
            },
            .{
                .api_name = "only_defs",
                .name = "only_defaults",
                .description = "Whether to only filter for default WCKeys",
                .parser = .flags_int,
            },
            .{
                .api_name = "usage_start",
                .name = "start_time",
                .description = "Filter for Jobs which started at this UNIX Timestamp",
                .parser = .integer,
            },
            .{
                .api_name = "usage_end",
                .name = "end_time",
                .description = "Filter for Jobs which ended at this UNIX Timestamp",
                .parser = .integer,
            },
            .{
                .api_name = "user_list",
                .name = "user",
                .description = "User to filter for",
                .parser = .list,
            },
    //      .{
    //          .name = "preempt_mode",
    //          .description = "Preempt Mode to filter for",
    //          .parse = TODO,
    //      },
        } ++ FlagsParameters,
    };
};

pub const path = struct {
    pub const IDParameter: openapi.PathParameterComponent = .{
        .api_type = models.IDPathParameter([]const u8),
        .parameters = &.{
            .{
                .name = "id",
                .description = "ID of the WCKey to operate on",
                .type = .string,
            },
        },
    };
};
