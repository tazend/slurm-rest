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
    .serde = .object(.container),
};

pub const Partition: SchemaComponent = .{
    .api_type = slurm.Partition,
    .ignored_fields = &.{
        "node_inx", "job_defaults_list",
    },
    .properties = &.{
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
            .name = "cluster_name",
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
            // TODO: Needs parsing
            .name = "def_mem_per_cpu",
            .description = "Suspend Timeout",
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
            .name = "name",
            .description = "Name of the Partition",
            .serde = .string(.native),
        },
        .{
            .name = "nodes",
            .description = "Nodes configured in this Partition",
            .serde = .string(.native),
        },
        .{
            .name = "nodesets",
            .description = "Nodesets configured for this Partition",
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
            // TODO: This is an enum
            .name = "state",
            .description = "Partition State",
            .serde = .string(.native),
//            .ref = slurm.Partition.State,
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
        .{
            .name = "total_cpus",
            .description = "Total amount of CPUs available",
            .serde = .integer(.native_zero_is_noval),
        },
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

pub const Association: SchemaComponent = .{
    .api_type = slurm.db.Association,
    .ignored_fields = &.{
        "assoc_next", "assoc_next_id", "user_rec", "accounting_list",
        "max_tres_mins_ctld", "max_tres_run_mins_ctld", "max_tres_ctld",
        "max_tres_pn_ctld", "grp_tres_ctld", "grp_tres_mins_ctld",
        "grp_tres_run_mins_ctld", "usage", "leaf_usage",
    },
    .properties = &.{
        .{
            .api_name = "acct",
            .name = "account",
            .description = "Name of the Account",
            .serde = .string(.native),
        },
//      .{
//          .api_name = "bf_usage",
//          .name = "backfill_usage",
//          .description = "Backfill Usage",
//          .serde = .object(.container),
//      },
        .{
            .name = "cluster",
            .description = "Name of the Cluster",
            .serde = .string(.native),
        },
        .{
            .name = "comment",
            .description = "Arbitrary Comment",
            .serde = .string(.native),
        },
        .{
            .name = "flags",
            .description = "Association Flags",
            .serde = .array(.bitflag),
        },
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
            .name = "id",
            .description = "Association ID",
            .serde = .integer(.native),
        },
        .{
            .api_name = "is_def",
            .name = "is_default",
            .description = "Whether this is the Users default Association",
            .serde = .boolean(.int),
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
            .api_name = "parent_acct",
            .name = "parent_account",
            .description = "Parent Account",
            .serde = .string(.native),
        },
        .{
            .name = "parent_id",
            .description = "Parent Association ID",
            .serde = .integer(.native),
        },
        .{
            .name = "partition",
            .description = "Partition assigned",
            .serde = .string(.native),
        },
        .{
            .name = "priority",
            .description = "Priority",
            .serde = .integer(.native_infinite_is_null),
        },
        // TODO: Support List of Strings
//      .{
//          .name = "qos_list",
//          .description = "List of QoS the Association can use",
//          .serde = .array(.list),
//      },
        .{
            .api_name = "shares_raw",
            .name = "shares",
            .description = "Association Shares",
            .serde = .integer(.native_infinite_is_null),
        },
        .{
            .name = "uid",
            .description = "User ID",
            .serde = .integer(.native),
        },
        .{
            .name = "user",
            .description = "Name of the User",
            .serde = .string(.native),
        },
    },
};

pub const DBJob: SchemaComponent = .{
    .api_type = slurm.db.Job,
    .ignored_fields = &.{
        "first_step_ptr", "resv_id", "show_full", "state_reason_prev",
        "wckeyid",
    },
    .properties = &.{
        .{
            .name = "account",
            .description = "Name of the Account",
            .serde = .string(.native),
        },
        .{
            .name = "admin_comment",
            .description = "Admin Comment",
            .serde = .string(.native),
        },
        .{
            .name = "alloc_nodes",
            .description = "Amount of allocated nodes",
            .serde = .integer(.native),
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
        // TODO: Pending and max simultaenously running tasks
//      .{
//          .name = "array_task_str",
//          .description = "",
//          .serde = .integer(.native_zero_is_noval),
//      },
        .{
            .name = "associd",
            .description = "Association ID",
            .serde = .integer(.native),
        },
        .{
            .name = "blockid",
            .description = "Block ID",
            .serde = .string(.native),
        },
        .{
            .name = "cluster",
            .description = "Name of the Cluster",
            .serde = .string(.native),
        },
        .{
            .name = "constraints",
            .description = "List of Constraints",
            .serde = .array(.csv),
        },
        .{
            .name = "container",
            .description = "Name of the Container",
            .serde = .string(.native),
        },
        .{
            .name = "db_index",
            .description = "Database Index",
            .serde = .integer(.native),
        },
        .{
            .name = "derived_ec",
            .description = "Derived exit code",
            .serde = .integer(.native),
        },
        .{
            .api_name = "derived_es",
            .name = "comment",
            .description = "Arbitrary job comment",
            .serde = .string(.native),
        },
        .{
            .name = "elapsed",
            .description = "Elapsed amount of seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "eligible",
            .description = "Time when the Job was eligible to run",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "end",
            .description = "Time when the Job ended",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "env",
            .description = "Environment",
            .serde = .dict(.key_value, &.{ .string }),
        },
        .{
            .name = "extra",
            .description = "Extra information",
            .serde = .string(.native),
        },
        .{
            .name = "failed_node",
            .description = "Name of the Node that failed",
            .serde = .string(.native),
        },
        .{
            .name = "flags",
            .description = "Job flags",
            .serde = .array(.bitflag),
        },
        .{
            .name = "gid",
            .description = "User GID",
            .serde = .integer(.native),
        },
        .{
            .name = "het_job_id",
            .description = "Heterogenous Job ID",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "het_job_offset",
            .description = "Heterogenous Job offset",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .api_name = "jobid",
            .name = "id",
            .description = "Job ID",
            .serde = .integer(.native),
        },
        .{
            .api_name = "jobname",
            .name = "name",
            .description = "Job Name",
            .serde = .string(.native),
        },
        .{
            .name = "lineage",
            .description = "Lineage",
            .serde = .string(.native),
        },
        .{
            .name = "licenses",
            .description = "List of Licenses",
            .serde = .array(.csv),
        },
        .{
            .name = "mcs_label",
            .description = "MCS Label",
            .serde = .string(.native),
        },
        .{
            .name = "nodes",
            .description = "Nodes requested or allocated",
            .serde = .string(.native),
        },
        .{
            .name = "partition",
            .description = "Name of the Partition requested or allocated",
            .serde = .string(.native),
        },
        .{
            .name = "priority",
            .description = "Job priority",
            .serde = .integer(.native),
        },
        .{
            .name = "qosid",
            .description = "QoS ID",
            .serde = .integer(.native),
        },
        .{
            .name = "qos_req",
            .description = "QoS Requested",
            .serde = .string(.native),
        },
        .{
            .name = "req_cpus",
            .description = "Requested amount of CPUs",
            .serde = .integer(.native),
        },
        .{
            .name = "req_mem",
            .description = "Requested amount of Memory in MiB",
            .serde = .integer(.native),
        },
        .{
            .name = "requid",
            .description = "UID",
            .serde = .integer(.native),
        },
        .{
            .name = "restart_cnt",
            .description = "How many times the Job restarted",
            .serde = .integer(.native),
        },
        .{
            .api_name = "resv_name",
            .name = "reservation",
            .description = "Name of the Reservation in use",
            .serde = .string(.native),
        },
        .{
            .api_name = "resv_req",
            .name = "reservation_requested",
            .description = "Name of the Reservation that was requested",
            .serde = .string(.native),
        },
        .{
            .name = "script",
            .description = "Content of the batch script",
            .serde = .string(.native),
        },
        .{
            .name = "segment_size",
            .description = "Segment Size",
            .serde = .integer(.native),
        },
        .{
            .name = "start",
            .description = "Time when the Job started",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "state",
            .description = "State of the Job",
            .serde = .array(.bitflag),
        },
        .{
            .name = "steps",
            .description = "List of Steps",
            .ref = DBSteps,
            .serde = .array(.list),
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
            .name = "std_out",
            .description = "Path to Jobs' stdout",
            .serde = .string(.job_stdout),
        },
        .{
            .name = "submit",
            .description = "Time when the Job was submitted",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "submit_line",
            .description = "Submit Line",
            .serde = .string(.native),
        },
        .{
            .name = "suspended",
            .description = "How long in seconds the Job was suspended",
            .serde = .integer(.native),
        },
        .{
            .name = "system_comment",
            .description = "System Comment",
            .serde = .string(.native),
        },
        .{
            .name = "sys_cpu_sec",
            .description = "System CPU Seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "sys_cpu_usec",
            .description = "System CPU Microseconds",
            .serde = .integer(.native),
        },
        .{
            .name = "timelimit",
            .description = "Time Limit in Minutes",
            .serde = .integer(.native),
        },
        .{
            .name = "tot_cpu_sec",
            .description = "Total CPU Seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "tot_cpu_usec",
            .description = "Total CPU Microseconds",
            .serde = .integer(.native),
        },
        .{
            .api_name = "tres_alloc_str",
            .name = "tres_allocated",
            .description = "TRES allocated",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .api_name = "tres_req_str",
            .name = "tres_requested",
            .description = "TRES requested",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "uid",
            .description = "User ID",
            .serde = .integer(.native),
        },
        .{
            .name = "used_gres",
            .description = "Used GRES",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "user",
            .description = "User Name",
            .serde = .string(.native),
        },
        .{
            .name = "user_cpu_sec",
            .description = "User CPU Seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "user_cpu_usec",
            .description = "User CPU Microseconds",
            .serde = .integer(.native),
        },
        .{
            .name = "wckey",
            .description = "WCKey",
            .serde = .string(.native),
        },
        .{
            .name = "work_dir",
            .description = "Working Directory",
            .serde = .string(.native),
        },
    },
};

pub const DBStep: SchemaComponent = .{
    .api_type = slurm.db.Step,
    .ignored_fields = &.{
        "job_ptr",
    },
    .properties = &.{
        .{
            .name = "container",
            .description = "Container",
            .serde = .string(.native),
        },
        .{
            .name = "cwd",
            .description = "Working Directory",
            .serde = .string(.native),
        },
        .{
            .name = "elapsed",
            .description = "Number of seconds elapsed",
            .serde = .integer(.native),
        },
        .{
            .name = "end",
            .description = "Time when the Step ends",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "exitcode",
            .description = "Step exitcode",
            .serde = .integer(.std),
        },
        .{
            .api_name = "nnodes",
            .name = "node_count",
            .description = "Number of Nodes allocated",
            .serde = .integer(.native),
        },
        .{
            .name = "nodes",
            .description = "Nodes allocated to the Step",
            .serde = .string(.native),
        },
        .{
            .name = "ntasks",
            .description = "Step number of Tasks",
            .serde = .integer(.native),
        },
        .{
            .name = "pid_str",
            .description = "Step PIDs",
            .serde = .string(.native),
        },
        .{
            .name = "req_cpufreq_min",
            .description = "Minimum CPU Frequency requested",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "req_cpufreq_max",
            .description = "Maximum CPU Frequency requested",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
        // TODO: Better format
            .name = "req_cpufreq_gov",
            .description = "CPU Frequency Governor requested",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "requid",
            .description = "Requested UID",
            .serde = .integer(.native),
        },
        .{
            .name = "start",
            .description = "Time when the Step started",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "state",
            .description = "Step State",
            .serde = .object(.native),
        },
//      .{
//          .name = "stats",
//          .description = "Job Stats",
//          .serde = .object(.container),
//      },
        .{
            .name = "step_id",
            .description = "Step ID Infos",
            .serde = .object(.container),
        },
        .{
            .api_name = "stepname",
            .name = "name",
            .description = "Name of the Step",
            .serde = .string(.native),
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
            .name = "std_out",
            .description = "Path to Jobs' stdout",
            .serde = .string(.job_stdout),
        },
        .{
            .name = "submit_line",
            .description = "Submit Line",
            .serde = .string(.native),
        },
        .{
            .name = "suspended",
            .description = "How long in seconds the Step was suspended",
            .serde = .integer(.native),
        },
        .{
            .name = "sys_cpu_sec",
            .description = "System CPU Seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "sys_cpu_usec",
            .description = "System CPU Microseconds",
            .serde = .integer(.native),
        },
//      .{
//          .name = "task_dist",
//          .description = "Task Distribution",
//          .serde = .array(.bitflag),
//      },
        .{
            .name = "timelimit",
            .description = "Time Limit in Minutes",
            .serde = .integer(.native),
        },
        .{
            .name = "tot_cpu_sec",
            .description = "Total CPU Seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "tot_cpu_usec",
            .description = "Total CPU Microseconds",
            .serde = .integer(.native),
        },
        .{
            .api_name = "tres_alloc_str",
            .name = "tres_allocated",
            .description = "TRES allocated",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "user_cpu_sec",
            .description = "User CPU Seconds",
            .serde = .integer(.native),
        },
        .{
            .name = "user_cpu_usec",
            .description = "User CPU Microseconds",
            .serde = .integer(.native),
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
        "array_bitmap", "fed_siblings_active_str", "fed_siblings_viable_str",
        "job_size_str",
        "job_resrcs",
        "oom_kill_step",
        "deadline",
    },
    .properties = &.{
        .{
            .name = "account",
            .description = "Name of the Account the Job runs under",
            .serde = .string(.native),
        },
        .{
            .name = "accrue_time",
            .description = "Accrue time",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "admin_comment",
            .description = "Comment set by the Admin",
            .serde = .string(.native),
        },
        .{
            .api_name = "alloc_node",
            .name = "submit_host",
            .description = "Host where this Job was submitted from",
            .serde = .string(.native),
        },
        .{
            .api_name = "alloc_sid",
            .name = "submit_sid",
            .description = "Submission SID",
            .serde = .integer(.native),
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
            .name = "array_task_str",
            .description = "Array Task str",
            .serde = .string(.native),
        },
        .{
            .api_name = "assoc_id",
            .name = "association_id",
            .description = "ID of the Association the Job runs under",
            .serde = .integer(.native),
        },
        .{
            .name = "batch_features",
            .description = "Batch Features requested by the Job",
            .serde = .string(.native),
        },
        .{
            .api_name = "batch_flag",
            .name = "is_batch",
            .description = "Whether the Job is a Batch Job or not",
            .serde = .boolean(.int),
        },
        .{
            .name = "batch_host",
            .description = "Name of the Host where the Batch Step runs",
            .serde = .string(.native),
        },
        .{
            .api_name = "bitflags",
            .name = "flags",
            .description = "Certain Job Flags",
            .serde = .array(.bitflag),
        },
        .{
            .name = "boards_per_node",
            .description = "How many boards per Node the Job requests",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "burst_buffer",
            .description = "Burst Buffer Info",
            .serde = .string(.native),
        },
        .{
            .name = "burst_buffer_state",
            .description = "Burst Buffer State",
            .serde = .string(.native),
        },
        .{
            .name = "cluster",
            .description = "Name of the Cluster for this Job",
            .serde = .string(.native),
        },
        .{
            .name = "cluster_features",
            .description = "Cluster features required by this Job",
            .serde = .string(.native),
        },
        .{
            .name = "command",
            .description = "sbatch Command",
            .serde = .string(.native),
        },
        .{
            .name = "comment",
            .description = "Arbitrary Job comment",
            .serde = .string(.native),
        },
        .{
            .name = "container",
            .description = "Name of the Container the Job uses",
            .serde = .string(.native),
        },
        .{
            .name = "container_id",
            .description = "Container ID",
            .serde = .string(.native),
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
            .name = "billable_tres",
            .description = "Billable TRES",
            .serde = .integer(.std),
        },
        .{
            .name = "cpus_per_task",
            .description = "CPUs Per Task requested",
            .serde = .integer(.native),
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
            .name = "cronspec",
            .description = "Cron specification",
            .serde = .string(.native),
        },
        .{
            .name = "deadline",
            .description = "Job deadline as UNIX Timestamp",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "delay_boot",
            .description = "Delay the boot of the Node(s) by this amount of minutes",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            // TODO: Proper format
            .name = "dependency",
            .description = "Job dependencies",
            .serde = .string(.native),
        },
        .{
            .name = "derived_ec",
            .description = "Derived exit code",
            .serde = .integer(.std),
        },
        .{
            .name = "eligible_time",
            .description = "UNIX Timestamp of when the Job was selected eligible",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "end_time",
            .description = "UNIX Timestamp of when the Job ends",
            .serde = .integer(.timestamp),
        },
        .{
            .api_name = "exc_nodes",
            .name = "excluded_nodes",
            .description = "Excluded Nodes",
            .serde = .string(.native),
        },
        .{
            .name = "exit_code",
            .description = "Exit code",
            .serde = .integer(.std),
        },
        .{
            .name = "extra",
            .description = "Some extra information",
            .serde = .string(.native),
        },
        .{
            .name = "failed_node",
            .description = "Node that caused the Job to fail",
            .serde = .string(.native),
        },
        .{
            .name = "features",
            .description = "Features requested by the Job",
            .serde = .array(.csv),
        },
        .{
            .api_name = "fed_origin_str",
            .name = "federation_origin",
            .description = "Federation origin",
            .serde = .string(.native),
        },
        .{
            .api_name = "fed_siblings_active",
            .name = "federation_siblings_active",
            .description = "Federation siblings active",
            .serde = .integer(.native),
        },
        .{
            .api_name = "fed_siblings_viable",
            .name = "federation_siblings_viable",
            .description = "Federation siblings viable",
            .serde = .integer(.native),
        },
        // TODO:
     // .{
     //     .api_name = "gres_detail_str",
     //     .name = "gres_detail",
     //     .description = "GRES Details",
     //     .serde = .dict(.gres),
     // },
        .{
            .name = "gres_total",
            .description = "GRES Total",
            .serde = .dict(.gres_count, &.{ .string, .integer }),
        },
        .{
            .name = "group_id",
            .description = "Group ID of the user owning the Job",
            .serde = .integer(.native),
        },
        .{
            .name = "het_job_id",
            .description = "Heterogenous Job ID",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "het_job_id_set",
            .description = "Heterogenous Job ID Range",
            .serde = .string(.native),
        },
        .{
            .name = "het_job_offset",
            .description = "Heterogenous Job Offset",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "state",
            .description = "State of the Job",
            .serde = .array(.bitflag),
        },
        .{
            .api_name = "last_sched_eval",
            .name = "last_sched_evaluation",
            .description = "Last Scheduling Evaluation",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "licenses",
            .description = "Required Licenses",
            .serde = .array(.csv),
        },
        .{
            .name = "licenses_allocated",
            .description = "Allocated Licenses",
            .serde = .array(.csv),
        },
        .{
            .name = "mail_type",
            .description = "Mail Event types",
            .serde = .array(.bitflag),
        },
        .{
            .name = "mail_user",
            .description = "User that receives E-Mail notifications",
            .serde = .string(.native),
        },
        .{
            .name = "max_cpus",
            .description = "Maximum Number of CPUs per Node",
            .serde = .object(.number_zero_is_noval),
        },
        .{
            .name = "max_nodes",
            .description = "Maximum Nodes",
            .serde = .object(.number_zero_is_noval),
        },
        .{
            .name = "mcs_label",
            .description = "Multi-Category Security Label",
            .serde = .string(.native),
        },



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
            .extra = true,
        },
    },
};

pub const Step: SchemaComponent = .{
    .api_type = slurm.Step,
    .ignored_fields = &.{
        "node_inx",
    },
    .properties = &.{
        .{
            .name = "array_job_id",
            .description = "Array ID of the Step",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "array_task_id",
            .description = "Array Task ID of the Step",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "cluster",
            .description = "Name of the Cluster this Step runs on",
            .serde = .string(.native),
        },
        .{
            .name = "container",
            .description = "Container for the Step",
            .serde = .string(.native),
        },
        .{
            .name = "container_id",
            .description = "Container ID for the Step",
            .serde = .string(.native),
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
            .name = "cwd",
            .description = "Working directory",
            .serde = .string(.native),
        },
        .{
            .name = "mem_per_tres",
            .description = "Memory per TRES",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "name",
            .description = "Name of the Step",
            .serde = .string(.native),
        },
        .{
            .name = "job_name",
            .description = "Name of the Parent Job",
            .serde = .string(.native),
        },
        .{
            .name = "network",
            .description = "Network Information",
            .serde = .string(.native),
        },
        .{
            .name = "nodes",
            .description = "Nodes assigned to the Step",
            .serde = .string(.native),
        },
        .{
            .api_name = "num_cpus",
            .name = "cpus",
            .description = "Number of CPUs the Step uses",
            .serde = .integer(.native),
        },
        .{
            .api_name = "num_tasks",
            .name = "ntasks",
            .description = "Number of Tasks the Step uses",
            .serde = .integer(.native),
        },
        .{
            .name = "partition",
            .description = "Name of the Partition the Step runs in",
            .serde = .string(.native),
        },
        .{
            .api_name = "resv_ports",
            .name = "reserved_ports",
            .description = "Reserved Ports",
            .serde = .string(.native),
        },
        .{
            .name = "run_time",
            .description = "Step runtime",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "srun_host",
            .description = "srun Host",
            .serde = .string(.native),
        },
        .{
            .name = "srun_pid",
            .description = "srun pid",
            .serde = .integer(.native),
        },
        .{
            .name = "start_time",
            .description = "Time when the Step started",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "start_protocol_ver",
            .description = "Protocol version the Step started with",
            .serde = .integer(.native),
        },
//      .{
//          .name = "state",
//          .description = "State of the step",
//          .serde = .integer(.native),
//      },
        .{
            .name = "step_id",
            .description = "Step ID",
            .serde = .object(.container),
        },
        .{
            .name = "std_err",
            .description = "Path to stderr",
            .serde = .string(.job_stderr),
        },
        .{
            .name = "std_in",
            .description = "Path to stdin",
            .serde = .string(.job_stdin),
        },
        .{
            .name = "std_out",
            .description = "Path to stdout",
            .serde = .string(.job_stdout),
        },
        .{
            .name = "submit_line",
            .description = "Submit Line for the Step",
            .serde = .string(.native),
        },
        .{
            .name = "task_dist",
            .description = "Task Distribution",
            .serde = .array(.bitflag),
        },
        .{
            .name = "time_limit",
            .description = "Step Time Limit",
            .serde = .object(.number),
        },
        .{
            .name = "tres_bind",
            .description = "TRES Binding",
            .serde = .string(.native),
        },
        .{
            .api_name = "tres_fmt_alloc_str",
            .name = "tres",
            .description = "Allocated TRES",
            .serde = .dict(.key_value, &.{ .string, .integer }),
        },
        .{
            .name = "tres_freq",
            .description = "TRES Frequency",
            .serde = .string(.native),
        },
        .{
            .name = "tres_per_step",
            .description = "TRES per Step",
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
            .name = "user_id",
            .description = "UID for the Step",
            .serde = .integer(.native),
        },
        .{
            .name = "user_name",
            .description = "User Name for the Step",
            .serde = .string(.user_name),
        },
    },
};

pub const StepID: SchemaComponent = .{
    .api_type = slurm.Step.ID,
    .properties = &.{
        .{
            .name = "sluid",
            .description = "Sluid",
            .serde = .string(.sluid),
            .extra = true,
        },
        .{
            .name = "step_het_comp",
            .description = "Step Het comp",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "job_id",
            .description = "Job ID",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "step_id",
            .description = "Step ID",
            .serde = .string(.step_id),
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
            .ref = Coordinators,
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
pub const Associations:      SchemaComponent = .array(Association, .list);
pub const DBJobs:            SchemaComponent = .array(DBJob, .list);
pub const DBSteps:           SchemaComponent = .array(DBStep, .list);
pub const Coordinators:      SchemaComponent = .array(Coordinator, .list);
pub const Users:             SchemaComponent = .array(User, .list);
pub const WCKeys:            SchemaComponent = .array(WCKey, .list);
pub const Jobs:              SchemaComponent = .array(Job, .load_response);
pub const Reservations:      SchemaComponent = .array(Reservation, .load_response);
pub const Partitions:        SchemaComponent = .array(Partition, .load_response);
pub const Nodes:             SchemaComponent = .array(Node, .load_response);
pub const Steps:             SchemaComponent = .array(Step, .load_response);

pub const AccountsResponse =     GenericResponse("Accounts", "List of Accounts");
pub const AssociationsResponse = GenericResponse("Associations", "List of Associations");
pub const DBJobsResponse =       GenericResponse("DBJobs", "List of Database Jobs");
pub const DBStepsResponse =      GenericResponse("DBSteps", "List of Database Steps");
pub const CoordinatorsResponse = GenericResponse("Coordinators", "List of Database Coordinators");
pub const UsersResponse =        GenericResponse("Users", "List of Database Users");
pub const WCKeysResponse =       GenericResponse("WCKeys", "List of Database WCKeys");
pub const JobResponse =          GenericResponse("Job", "Job information");
pub const NodeResponse =         GenericResponse("Node", "Node information");
pub const PartitionResponse =    GenericResponse("Partition", "Partition information");
pub const ReservationResponse =  GenericResponse("Reservation", "Reservation information");
pub const DBJobResponse =        GenericResponse("DBJob", "Database Job Information");

pub const JobScriptResponse: SchemaComponent = .{
    .api_type = models.JobScriptResponse,
    .properties = &.{
        .{
            .name = "script",
            .description = "Job script",
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

pub const NodesResponse: SchemaComponent = .{
    .api_type = models.NodesResponse,
    .properties = &.{
        .{
            .name = "last_update",
            .description = "Time of last update of this data",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "nodes",
            .description = "List of Steps",
            .ref = Nodes,
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

pub const BaseResponse: SchemaComponent = .{
    .api_type = models.BaseResponse,
    .properties = &.{
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

pub const StepsResponse: SchemaComponent = .{
    .api_type = models.StepsResponse,
    .properties = &.{
        .{
            .name = "last_update",
            .description = "Time of last update of this data",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "steps",
            .description = "List of Steps",
            .ref = Steps,
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

pub const PartitionsResponse: SchemaComponent = .{
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

pub const ReservationsResponse: SchemaComponent = .{
    .api_type = models.ReservationsResponse,
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
    .api_type = models.JobsResponse,
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
