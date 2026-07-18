const std = @import("std");
const SerdeContext = @import("json/SerdeContext.zig");
const dump = @import("json/parse.zig");
const JSONType = SerdeContext.JSONType;
const slurm = @import("slurm");
const models = @import("models.zig");
const ser = @import("json/new_dump_methods.zig");
const Parser = @import("json/Parser.zig");

/// A specific Member or "Property" of a Schema Component
pub const Property = struct {
    api_name: ?[:0]const u8 = null,
    name: [:0]const u8,
    description: []const u8,
    serde: SerdeContext = .noop(),
    ref: ?SchemaComponent = null,
    // Whether this component is being considered for dumping/parsing without
    // existing on the API Type itself.
    extra: bool = false,
};

/// A Top-Level Schema Component
/// For example, this can be a "Node" or a "Job"
pub const SchemaComponent = struct {
    api_type: type,
//    description: []const u8,
    serde: SerdeContext = .object(.container),
    properties: []const Property = &.{},
    ignored_fields: []const []const u8 = &.{},

    pub fn array(comptime T: SchemaComponent, comptime A: SerdeContext.ArrayTypes) SchemaComponent {
        return .{
            .api_type = switch (A) {
                .list => slurm.List(*T.api_type),
                .load_response => T.api_type.LoadResponse,
                else => T.api_type,
            },
            .serde = .array(A),
        };
    }
};

pub fn GenericResponse(comptime name: [:0]const u8, comptime what: []const u8) SchemaComponent {
    if (!@hasDecl(@This(), name)) {
        @compileError("There is no SchemaComponent available for: '" ++ name ++ "'");
    }

    const T = @field(@This(), name);

    const decls = @typeInfo(models).@"struct".decls;
    const Response = blk: {
        for (decls) |decl| {
            const field = @field(models, decl.name);
            const Info = @typeInfo(@TypeOf(field));
            if (Info == .type) {
                if (@typeInfo(field) == .@"struct") {
                    if (@hasDecl(field, "Schema") and @TypeOf(field.Schema) == SchemaComponent) {
                        if (field.Schema.api_type == T.api_type) {
                            break :blk field;
                        }
                    }
                }
            }

        }
        @compileError("No response implementation found for " ++ @typeName(T.api_type));
    };

    const name_lower = comptime blk: {
        var buf: [name.len:0]u8 = undefined;
        buf[name.len] = 0;
        _ = std.ascii.lowerString(buf[0..name.len], name);
        break :blk buf;
    };

    return .{
        .api_type = Response,
        .properties = &.{
            .{
                .api_name = "data",
                .name = &name_lower,
                .description = what,
                .ref = T,
                .serde = .string(.print),
            },
            .{
                .name = "meta",
                .description = "Metadata",
                .ref = Meta,
                .serde = .object(.native),
            },
            .{
                .name = "error",
                .description = "Errors",
                .ref = Error,
                .serde = .object(.native),
            },
        },
        .serde = .object(.container),
    };
}

pub const Error: SchemaComponent = .{
    .api_type = models.Error,
    .properties = &.{
        .{
            .name = "title",
            .description = "Name of the Error",
            .serde = .string(.native),
        },
        .{
            .name = "detail",
            .description = "Explanation of the Error that occured",
            .serde = .string(.native),
        },
    },
};

pub const SlurmVersion: SchemaComponent = .{
    .api_type = models.SlurmVersion,
    .properties = &.{
        .{
            .name = "major",
            .description = "Major Version of Slurm",
            .serde = .integer(.native),
        },
        .{
            .name = "major",
            .description = "Major Version of Slurm",
            .serde = .integer(.native),
        },
        .{
            .name = "major",
            .description = "Major Version of Slurm",
            .serde = .integer(.native),
        },
    },
};

pub const SlurmMeta: SchemaComponent = .{
    .api_type = models.SlurmMeta,
    .properties = &.{
        .{
            .name = "cluster",
            .description = "Name of the cluster",
            .serde = .string(.native),
        },
        .{
            .name = "release",
            .description = "Slurm Release string",
            .serde = .string(.native),
        },
        .{
            .name = "version",
            .description = "Major, Minor and Micro version of Slurm",
            .ref = SlurmVersion,
            .serde = .object(.native),
        },
    },
};

pub const Meta: SchemaComponent = .{
    .api_type = models.Meta,
    .properties = &.{
        .{
            .name = "slurm",
            .description = "Slurm specific Metadata",
            .ref = SlurmMeta,
            .serde = .object(.native),
        },
    },
};

pub const AssociationShort: SchemaComponent = .{
    .api_type = models.AssociationShort,
    .properties = &.{
        .{
            .name = "account",
            .description = "Name of the Account",
            .serde = .string(.native),
        },
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
    },
    .serde = .object(.native),
};

pub const Partition: SchemaComponent = .{
    .api_type = slurm.Partition,
    .ignored_fields = &.{
        "node_inx", "job_defaults_list",
    },
    .properties = &.{
        .{
            .name = "allowed_alloc_nodes",
            .description = "Names of Nodes from which can be submitted to this Partition",
            .serde = .array(.csv),
        },
        .{
            .name = "allowed_accounts",
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
            .name = "deny_accounts",
            .description = "Accounts that can't submit to this Partition",
            .serde = .array(.csv),
        },
        .{
            .api_name = "job_defaults_str",
            .name = "job_defaults",
            .description = "Job defaults",
            .serde = .array(.csv),
        },
        .{
            .name = "suspend_timeout",
            .description = "Suspend Timeout",
            .serde = .object(.number),
        },
        // TODO: Needs parsing
        .{
            .name = "def_mem_per_cpu",
            .description = "Suspend Timeout",
            .serde = .object(.number),
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
            .name = "max_nodes",
            .description = "Maximum Nodes",
            .serde = .object(.number),
        },
        .{
            .name = "resume_timeout",
            .description = "Resume Timeout",
            .serde = .object(.number),
        },
        .{
            .name = "over_time_limit",
            .description = "Over Time Limit",
            .serde = .object(.number),
        },
        .{
            .name = "deny_qos",
            .description = "Names of QoS that cannot run in this Partition",
            .serde = .array(.csv),
        },
        .{
            .api_name = "qos_char",
            .name = "assigned_qos",
            .description = "QoS assigned to this Partition",
            .serde = .string(.native),
        },
        .{
            .api_name = "tres_fmt_str",
            .name = "configured_tres",
            .description = "Total TRES configured",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
    },
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

pub const Account: SchemaComponent = .{
    .api_type = slurm.db.Account,
    .properties = &.{
        .{
            .api_name = "assoc_list",
            .name = "associations",
            .description = "List of Associations (short-form) for the Account.",
            .serde = .array(.assocs_short),
            .ref = AssociationsShort,
        },
        .{
            .name = "coordinators",
            .description = "List of Coordinators",
            .serde = .array(.list),
            .ref = Coordinator,
        },
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
    },
};

pub const Reservation: SchemaComponent = .{
    .api_type = slurm.Reservation,
    .ignored_fields = &.{
        "node_inx", "core_spec_cnt",
    },
    .properties = &.{
        .{
            .name = "burst_buffer",
            .description = "Burst Buffer Information",
            .serde = .string(.native),
        },
        .{
            .name = "comment",
            .description = "Arbitrary comment",
            .serde = .string(.native),
        },
        .{
            .api_name = "core_cnt",
            .name = "cores",
            .description = "Number of Cores reserved",
            .serde = .integer(.native),
        },
        .{
            .name = "end_time",
            .description = "Time when the Reservation ends",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "flags",
            .description = "List of Flags",
            .serde = .array(.bitflag),
        },
        .{
            .name = "max_start_delay",
            .description = "Maximum start delay",
            .serde = .integer(.native),
        },
        .{
            .name = "name",
            .description = "Name of the Reservation",
            .serde = .string(.native),
        },
        .{
            .name = "purge_comp_time",
            .description = "Purge Completion Time",
            .serde = .integer(.native),
        },
        .{
            .name = "qos",
            .description = "Quality of Service assigned",
            .serde = .string(.native),
        },
        .{
            .name = "start_time",
            .description = "Time when the Reservation starts",
            .serde = .integer(.timestamp),
        },
        .{
            .api_name = "core_spec",
            .name = "specialized_cores",
            .description = "Cores Reserved for the System",
            .serde = .{
                .dump = ser.resCoreSpec,
                .parse = Parser.unsupported,
                .json_type = .object,
            },
        },
        .{
            .api_name = "tres_str",
            .name = "tres",
            .description = "TRES reserved",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .api_name = "node_cnt",
            .name = "node_count",
            .description = "Total number of nodes reserved",
            .serde = .integer(.native),
        },
        .{
            .api_name = "node_list",
            .name = "nodes",
            .description = "Nodes reserved",
            .serde = .string(.native),
        },
        .{
            .name = "licenses",
            .description = "Names of Licenses in this Reservation",
            .serde = .array(.csv),
        },
        .{
            .name = "groups",
            .description = "Names of Groups allowed",
            .serde = .array(.csv),
        },
        .{
            .name = "features",
            .description = "Names of Features",
            .serde = .array(.csv),
        },
        .{
            .name = "allowed_parts",
            .description = "List of allowed Partitions",
            .serde = .array(.csv),
        },
        .{
            .name = "accounts",
            .description = "List of allowed Accounts",
            .serde = .array(.csv),
        },
        .{
            .name = "users",
            .description = "List of allowed Users",
            .serde = .array(.csv),
        },
    },
};

pub const Job: SchemaComponent = .{
    .api_type = slurm.Job,
    .ignored_fields = &.{
        "node_inx", "priority_array", "req_node_inx", "exc_node_inx",
        "array_bitmap",
        // TODO:
        "gres_detail_str",
        "oom_kill_step",
        "deadline",
    },
    .properties = &.{
        .{
            .api_name = "pn_min_memory",
            .name = "memory",
            .description = "Memory per Node or CPU",
            .serde = .integer(.job_memory),
        },
        .{
            .api_name = "tres_req_str",
            .name = "tres_requested",
            .description = "TRES requested by the Job",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .api_name = "tres_alloc_str",
            .name = "tres_allocated",
            .description = "TRES currently allocated to the Job",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "tres_per_job",
            .description = "TRES per Job",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "tres_per_node",
            .description = "TRES per Node",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "tres_per_socket",
            .description = "TRES per Socket",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "tres_per_task",
            .description = "TRES per Task",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "threads_per_core",
            .description = "Threads per Core",
            .serde = .object(.number),
        },
        .{
            .name = "requeue",
            .description = "Whether the job can be requeued or not",
            .serde = .boolean(.int),
        },
        .{
            .name = "array_job_id",
            .description = "Array ID of the Job",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "array_task_id",
            .description = "Array Task ID of the Job",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "array_max_tasks",
            .description = "How many Array Tasks can run simultaneously",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .api_name = "batch_flag",
            .name = "is_batch",
            .description = "Whether the Job is a Batch Job or not",
            .serde = .boolean(.int),
        },
        .{
            .name = "boards_per_node",
            .description = "How many boards per Node the Job requests",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .api_name = "state_desc",
            .name = "state_description",
            .description = "State Description",
            .serde = .string(.native),
        },
        .{
            .api_name = "wait4switch",
            .name = "wait_for_switch",
            .description = "How long to wait for Switches",
            .serde = .integer(.native),
        },
        .{
            .name = "contiguous",
            .description = "Whether the Job requests contiguous nodes",
            .serde = .boolean(.int),
        },
        .{
            .api_name = "core_spec",
            .name = "specialized_cores",
            .description = "Number of Cores reserved for System",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "cores_per_socket",
            .description = "Number of Cores per Socket requested",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "cpu_freq_min",
            .description = "Minimum CPU Frequency",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "cpu_freq_max",
            .description = "Maximum CPU Frequency",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
        // TODO: Better format
            .name = "cpu_freq_gov",
            .description = "CPU Frequency Governor",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "cpus_per_tres",
            .description = "CPUs per TRES",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .api_name = "exc_nodes",
            .name = "excluded_nodes",
            .description = "Excluded Nodes",
            .serde = .string(.native),
        },
        .{
            .name = "features",
            .description = "Features requested by the Job",
            .serde = .array(.csv),
        },
        .{
            .name = "het_job_id",
            .description = "Heterogenous Job ID",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "ntasks_per_core",
            .description = "Number of Tasks per Core",
            .serde = .object(.number),
        },
        .{
            .name = "ntasks_per_tres",
            .description = "Number of Tasks per TRES",
            .serde = .object(.number),
        },
        .{
            .name = "ntasks_per_node",
            .description = "Number of Tasks per Node",
            .serde = .object(.number),
        },
        .{
            .name = "ntasks_per_socket",
            .description = "Number of Tasks per Socket",
            .serde = .object(.number),
        },
        .{
            .name = "ntasks_per_board",
            .description = "Number of Tasks per Board",
            .serde = .object(.number),
        },
        .{
            .name = "sockets_per_node",
            .description = "Number of Sockets per Node",
            .serde = .object(.number),
        },
        .{
            .name = "sockets_per_board",
            .description = "Number of Sockets per Board",
            .serde = .object(.number_zero_is_noval),
        },
        .{
            .api_name = "pn_min_cpus",
            .name = "min_cpus_per_node",
            .description = "Minimum Number of CPUs per Node",
            .serde = .object(.number_zero_is_noval),
        },
        .{
            .name = "max_cpus",
            .description = "Maximum Number of CPUs per Node",
            .serde = .object(.number_zero_is_noval),
        },
        .{
            .name = "time_min",
            .description = "Minimum Time Limit",
            .serde = .object(.number_zero_is_noval),
        },
        .{
            .name = "std_out",
            .description = "Path to Jobs' stdout",
            .serde = .string(.job_stdout),
        },
        .{
            .name = "std_err",
            .description = "Path to Jobs' stderr",
            .serde = .string(.job_stderr),
        },
        .{
            .name = "std_in",
            .description = "Path to Jobs' stdin",
            .serde = .string(.job_stdin),
        },
        .{
            .name = "user_name",
            .description = "Name of the User who submitted this Job",
            .serde = .string(.user_name),
        },
        .{
            .name = "memory_total",
            .description = "Total memory allocated or requested by the Job",
            .serde = .integer(.job_memory_total),
        },
    },
};

pub const NodeUpdatable: SchemaComponent = .{
    .api_type = slurm.Node.Updatable,
    .properties = &.{
        .{
            .name = "comment",
            .description = "Comment for the Node",
            .serde = .string(.native),
        },
        .{
            .name = "cpu_bind",
            .description = "CPU Binding for the Node",
            .serde = .array(.bitflag),
        },
        .{
            .name = "features",
            .description = "List of features",
            .serde = .array(.csv),
        },
        .{
            .name = "gres",
            .description = "List of GRES",
            .serde = .dict(.key_value, &.{ .string }),
        },
    },
};

pub const Node: SchemaComponent = .{
    .api_type = slurm.Node,
    .properties = &.{
        .{
            .name = "alloc_cpus",
            .description = "Currently allocated CPUs",
            .serde = .integer(.native),
        },
        .{
            .name = "alloc_memory",
            .description = "Currently allocated Memory",
            .serde = .integer(.native),
        },
        .{
            .api_name = "alloc_tres_fmt_str",
            .name = "alloc_tres",
            .description = "Currently allocated TRES",
            .serde = .dict(.key_value, &.{ .integer, .string }),
        },
        .{
            .api_name = "arch",
            .name = "architecture",
            .description = "Architecture of the Node",
            .serde = .string(.native),
        },
        .{
            .name = "bcast_address",
            .description = "BCast Address",
            .serde = .string(.native),
        },
        .{
            .name = "boards",
            .description = "Number of Boards the node has",
            .serde = .integer(.native),
        },
        .{
            .name = "boot_time",
            .description = "Timestamp when the Node booted",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "cert_flags",
            .description = "Certificate flags",
            .serde = .array(.native),
        },
        .{
            .name = "cert_last_renewal",
            .description = "When the Certificate was last renewed",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "cluster_name",
            .description = "Name of the Cluster this Node belongs to",
            .serde = .string(.native),
        },
        .{
            .name = "cores",
            .description = "Cores per Socket configured",
            .serde = .integer(.native),
        },
        .{
            .api_name = "core_spec_cnt",
            .name = "specialized_cpus",
            .description = "Number of CPUs reserved for the System",
            .serde = .integer(.native),
        },
        .{
            .name = "cpu_bind",
            .description = "Default CPU Binding",
            .serde = .array(.native),
        },
        .{
            .name = "cpu_load",
            .description = "Current CPU Load",
            .serde = .integer(.native),
        },
        .{
            .api_name = "free_mem",
            .name = "free_memory",
            .description = "Free Memory of the Node, in MiB",
            .serde = .integer(.native),
        },
        .{
            .api_name = "cpus",
            .name = "total_cpus",
            .description = "Total CPUs configured",
            .serde = .integer(.native),
        },
        .{
            .api_name = "cpus_efctv",
            .name = "effective_cpus",
            .description = "Effective CPUS configured",
            .serde = .integer(.native),
        },
        .{
            .api_name = "cpu_spec_list",
            .name = "specialized_cpu_ids",
            .description = "Reserved CPU Ids",
            .serde = .array(.integers),
        },
        .{
            .name = "energy",
            .description = "Energy data of the node",
            .serde = .object(.container),
        },
        .{
            .name = "extra",
            .description = "Arbitrary String assigned to the node",
            .serde = .string(.native),
        },
        .{
            .api_name = "features_act",
            .name = "features_active",
            .description = "List of active Features",
            .serde = .array(.csv),
        },
        .{
            .api_name = "features",
            .name = "features_configured",
            .description = "List of configured Features",
            .serde = .array(.csv),
        },
        .{
            .name = "gres",
            .description = "GRES Configured",
            .serde = .dict(.gres_count, &.{ .integer }),
        },
        .{
            .name = "gres_used",
            .description = "GRES currently used",
            .serde = .array(.csv),
        },
        .{
            .name = "gres_drain",
            .description = "GRES that are Drained",
            .serde = .dict(.gres_count, &.{ .integer }),
        },
        .{
            .name = "instance_id",
            .description = "Node Instance ID",
            .serde = .string(.native),
        },
        .{
            .name = "instance_type",
            .description = "Node Instance Type",
            .serde = .string(.native),
        },
        .{
            .name = "last_busy",
            .description = "Timestamp when the Node had the last Job running",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "mcs_label",
            .description = "MCS Label Configured",
            .serde = .string(.native),
        },
        .{
            .api_name = "mem_spec_limit",
            .name = "specialized_memory",
            .description = "Memory reserved for the System",
            .serde = .integer(.native),
        },
        .{
            .name = "name",
            .description = "Name of the Node",
            .serde = .string(.native),
        },
        .{
            .api_name = "next_state",
            .name = "next_state_after_reboot",
            .description = "Next State the Node will be in after reboot",
            .serde = .object(.node_state),
        },
        .{
            .api_name = "node_addr",
            .name = "address",
            .description = "Address of the Node",
            .serde = .string(.native),
        },
        .{
            .api_name = "node_hostname",
            .name = "hostname",
            .description = "Hostname of the Node",
            .serde = .string(.native),
        },
        .{
            .name = "state",
            .description = "Current Node Status",
            .serde = .object(.node_state),
        },
        .{
            .api_name = "os",
            .name = "operating_system",
            .description = "Operating System of the Node",
            .serde = .string(.native),
        },
        .{
            .api_name = "owner",
            .name = "owner_uid",
            .description = "Node Owner UID",
            .serde = .integer(.native),
        },
        .{
            .name = "parameters",
            .description = "List of Parameters",
            .serde = .array(.csv),
        },
        .{
            .name = "partitions",
            .description = "List of Partitions",
            .serde = .array(.csv),
        },
        .{
            .name = "port",
            .description = "Port slurmd is listening on",
            .serde = .integer(.native),
        },
        .{
            .name = "real_memory",
            .description = "Memory configured for the Node",
            .serde = .integer(.native),
        },
        .{
            .name = "res_cores_per_gpu",
            .description = "Number of Cores restricted to GPUs",
            .serde = .integer(.native),
        },
        .{
            .api_name = "gpu_spec",
            .name = "cpus_reserved_for_gpus",
            .description = "Number of Cores reserved for Jobs also using a GPU",
            .serde = .string(.native),
        },
        .{
            .name = "comment",
            .description = "Arbitrary comment for the node",
            .serde = .string(.native),
        },
        .{
            .name = "reason",
            .description = "Reason that explains why a Node was set to Down or Drained",
            .serde = .string(.native),
        },
        .{
            .name = "reason_time",
            .description = "Timestamp when the Reason was set",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "reason_uid",
            .description = "UID of the User that set the Reason",
            .serde = .integer(.native),
        },
        .{
            .name = "resume_after",
            .description = "When the node will be resumed",
            .serde = .integer(.timestamp),
        },
        .{
            .api_name = "resv_name",
            .name = "reservation",
            .description = "Name of the Reservation this node is contained in",
            .serde = .string(.native),
        },
        .{
            .name = "slurmd_start_time",
            .description = "When slurmd on the Node started",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "sockets",
            .description = "Amount of sockets configured",
            .serde = .integer(.native),
        },
        .{
            .name = "threads",
            .description = "Amount of Threads available",
            .serde = .integer(.native),
        },
        .{
            .api_name = "tmp_disk",
            .name = "temporary_disk",
            .description = "Temporary Disk Space the Node offers",
            .serde = .integer(.native),
        },
        .{
            .api_name = "topology_str",
            .name = "topology",
            .description = "Node Topology",
            .serde = .string(.native),
        },
        .{
            .name = "weight",
            .description = "Weight assigned to the Node",
            .serde = .integer(.native),
        },
        .{
            .api_name = "tres_fmt_str",
            .name = "tres",
            .description = "Total configured TRES",
            .serde = .dict(.key_value, &.{ .integer, .string }),
        },
        .{
            .name = "version",
            .description = "Version of Slurm this Node is running on",
            .serde = .string(.native),
        },
        .{
            .name = "idle_cpus",
            .description = "Idle CPUs of the Node",
            .serde = .integer(.node_idle_cpus),
            .extra = true,
        },
//      .{
//          .name = "reason_user",
//          .description = "Name of the User who set the Reason",
//          .serde = .integer(.node_idle_cpus),
//          .extra = true,
//      },
    },
};

pub const AccountingGatherEnergy: SchemaComponent = .{
    .api_type = slurm.AccountingGatherEnergy,
    .properties = &.{
        .{
            .api_name = "ave_watts",
            .name = "average_watts",
            .description = "Average Wattage",
            .serde = .integer(.native),
        },
        .{
            .name = "base_consumed_energy",
            .description = "Base Consumed energy",
            .serde = .integer(.native),
        },
        .{
            .name = "consumed_energy",
            .description = "Energy Consumed",
            .serde = .integer(.native),
        },
        .{
            .name = "current_watts",
            .description = "Current Watts",
            .serde = .integer(.native),
        },
        .{
            .name = "previous_consumed_energy",
            .description = "Previous consumed energy",
            .serde = .integer(.native),
        },
        .{
            .name = "poll_time",
            .description = "Time this data was polled",
            .serde = .integer(.timestamp),
        },
    },
};

pub const WCKey: SchemaComponent = .{
    .api_type = slurm.db.WCKey,
    .properties = &.{
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
            .ref = AssociationsShort,
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
        },
    },
};

pub const AssociationsShort: SchemaComponent = .array(AssociationShort, .assocs_short);
pub const Accounts:          SchemaComponent = .array(Account, .list);
pub const Coordinators:      SchemaComponent = .array(Coordinator, .list);
pub const Users:             SchemaComponent = .array(User, .list);
pub const WCKeys:            SchemaComponent = .array(WCKey, .list);
pub const Jobs:              SchemaComponent = .array(Job, .load_response);
pub const Reservations:      SchemaComponent = .array(Reservation, .load_response);

pub const Nodes:             SchemaComponent = .array(Node, .load_response);
pub const NodesResponse = GenericResponse("Nodes", "List of Nodes");

pub const ReservationsResponse: SchemaComponent = .{
    .api_type = models.ReservationArrayResponse,
    .properties = &.{
        .{
            .name = "last_update",
            .description = "Time of last update of this data",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "reservations",
            .description = "List of Reservations",
            .ref = Reservations,
            .serde = .string(.print),
        },
        .{
            .name = "meta",
            .description = "Metadata",
            .ref = Meta,
            .serde = .object(.native),
        },
        .{
            .name = "error",
            .description = "Errors",
            .ref = Error,
            .serde = .object(.native),
        },
    },
};

pub const JobsResponse: SchemaComponent = .{
    .api_type = models.JobArrayReponse,
    .properties = &.{
        .{
            .name = "last_backfill",
            .description = "Time of Last backfill run",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "last_update",
            .description = "Time of last update of this data",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "jobs",
            .description = "List of Jobs",
            .ref = Jobs,
            .serde = .string(.print),
        },
        .{
            .name = "meta",
            .description = "Metadata",
            .ref = Meta,
            .serde = .object(.native),
        },
        .{
            .name = "error",
            .description = "Errors",
            .ref = Error,
            .serde = .object(.native),
        },
    },
};

test {
    _  = NodesResponse;
}
