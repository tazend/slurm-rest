pub const Partition: SchemaComponent = .{
    .api_type = slurm.Partition,
    .properties = NameMember ++ ReadOnlyMembers ++ UpdatableMembers,
};

pub const PartitionUpdatable: SchemaComponent = .{
    .api_type = slurm.Partition,
    .properties = UpdatableMembers,
};

pub const PartitionUpdatableArray: SchemaComponent = .array(
    PartitionUpdatable,
    .container,
);

pub const Partitions: SchemaComponent = .array(
    Partition,
    .load_response,
);

pub const PartitionResponse = openapi.GenericResponse(
    "Partition",
    "Partition Information",
);

pub const PartitionsResponse: SchemaComponent = .{
    .child = Partitions,
    .api_type = models.PartitionsResponse,
    .properties = &.{
        .{
            .name = "last_update",
            .description = "Time of last update of this data",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "partitions",
            .description = "List of Partitions",
            .ref = Partitions,
            .serde = .string(.print),
        },
        .{
            .name = "meta",
            .description = "Metadata",
            .ref = openapi.Meta,
            .serde = .object(.native),
        },
        .{
            .name = "error",
            .description = "Errors",
            .ref = openapi.Error,
            .serde = .object(.native),
        },
    },
};

const IgnoredMembers: []const []const u8 = &.{
    "node_inx", "job_defaults_list",
};

const ReadOnlyMembers: []const Property = &.{
    .{
        .name = "total_nodes",
        .description = "Total amount of Nodes available",
        .serde = .integer(.native_zero_is_noval),
    },
    .{
        .api_name = "tres_fmt_str",
        .name = "configured_tres",
        .description = "Total TRES configured",
        .serde = .dict(.key_value, &.{ .string, .integer }),
    },
    .{
        .api_name = "cluster_name",
        .name = "cluster",
        .description = "Name of the Cluster this Partition belongs to",
        .serde = .string(.native),
    },
    .{
        .api_name = "cr_type",
        .name = "select_type",
        .description = "Select Plugin",
        .serde = .array(.bitflag),
    },
    .{
        .name = "total_cpus",
        .description = "Total amount of CPUs available",
        .serde = .integer(.native_zero_is_noval),
    },
    .{
        .name = "nodesets",
        .description = "Nodesets configured for this Partition",
        .serde = .string(.native),
    },
};

const NameMember: []const Property = &.{
    .{
        .name = "name",
        .description = "Name of the Partition",
        .serde = .string(.native),
    },
};

const UpdatableMembers: []const Property = &.{
    .{
        .name = "allow_alloc_nodes",
        .description = "Names of Nodes from which can be submitted to this Partition",
        .serde = .array(.csv),
    },
    .{
        .name = "allow_accounts",
        .description = "Accounts allowed to run in this Partition",
        .serde = .array(.csv),
    },
    .{
        .name = "allow_groups",
        .description = "Names of groups that can run in this Partition",
        .serde = .array(.csv),
    },
    .{
        .name = "allow_qos",
        .description = "Names of QoS that can run in this Partition",
        .serde = .array(.csv),
    },
    .{
        .name = "alternate",
        .description = "Alternate Partition name",
        .serde = .string(.native),
    },
    .{
        .api_name = "billing_weights_str",
        .name = "tres_billing_weights",
        .description = "TRES Billing Weights",
        .serde = .dict(.key_value, &.{ .integer }),
    },
    .{
        // TODO: Needs parsing
        .name = "def_mem_per_cpu",
        .description = "Default Memory per CPU",
        .serde = .object(.number),
    },
    .{
        .name = "default_time",
        .description = "Default Time Limit",
        .serde = .integer(.native),
    },
    .{
        .name = "deny_accounts",
        .description = "Accounts that can't submit to this Partition",
        .serde = .array(.csv),
    },
    .{
        .name = "deny_qos",
        .description = "Names of QoS that cannot run in this Partition",
        .serde = .array(.csv),
    },
    .{
        .name = "flags",
        .description = "Partition Flags",
        .serde = .array(.bitflag),
    },
    .{
        .name = "grace_time",
        .description = "Grace time in seconds by which a job gets extended after being selected for preemption",
        .serde = .integer(.native),
    },
    .{
        .api_name = "job_defaults_str",
        .name = "job_defaults",
        .description = "Job defaults",
        .serde = .array(.csv),
    },
    .{
        .name = "max_cpus_per_node",
        .description = "Maximum CPUs per Node",
        .serde = .object(.number),
    },
    .{
        .name = "max_cpus_per_socket",
        .description = "Maximum CPUs per Socket",
        .serde = .object(.number),
    },
    .{
        .name = "max_mem_per_cpu",
        .description = "Maximum Memory per CPU",
        .serde = .object(.number),
    },
    .{
        .name = "max_nodes",
        .description = "Maximum Nodes",
        .serde = .object(.number),
    },
    .{
        .api_name = "max_share",
        .name = "max_shares",
        .description = "Whether a partition can execute more than one job on a resource",
        .serde = .integer(.native),
    },
    .{
        .name = "max_time",
        .description = "Maximum Time Limit",
        .serde = .object(.number),
    },
    .{
        .name = "min_nodes",
        .description = "Minimum Nodes",
        .serde = .object(.number),
    },
    .{
        .name = "nodes",
        .description = "Nodes configured in this Partition",
        .serde = .string(.native),
    },
    .{
        .name = "over_time_limit",
        .description = "Over Time Limit",
        .serde = .object(.number),
    },
    .{
        .name = "preempt_mode",
        .description = "Preemption Mode",
        .serde = .array(.bitflag),
    },
    .{
        .name = "priority_job_factor",
        .description = "Priority Job Factor configured",
        .serde = .object(.number),
    },
    .{
        .name = "priority_tier",
        .description = "Priority Tier of the Partition",
        .serde = .object(.number),
    },
    .{
        .api_name = "qos_char",
        .name = "assigned_qos",
        .description = "QoS assigned to this Partition",
        .serde = .string(.native),
    },
    .{
        .name = "resume_timeout",
        .description = "Resume Timeout",
        .serde = .object(.number),
    },
    .{
        .name = "state",
        .description = "Partition State",
        .serde = .string(.@"enum"),
    },
    .{
        .name = "suspend_time",
        .description = "Suspend Time",
        .serde = .object(.number),
    },
    .{
        .name = "suspend_timeout",
        .description = "Suspend Timeout",
        .serde = .object(.number),
    },
    .{
        .name = "topology_name",
        .description = "Name of the Topology used",
        .serde = .string(.native),
    },
};

const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;
const models = openapi.models;
