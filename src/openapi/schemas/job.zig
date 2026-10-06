const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;
const models = @import("../../models.zig");

pub const Jobs: SchemaComponent = .array(Job, .load_response);
pub const JobResponse = openapi.GenericResponse("Job", "Job information");

pub const JobScriptResponse: SchemaComponent = .{
    .api_type = models.JobScriptResponse,
    .properties = [_]Property{
        .{
            .name = "script",
            .description = "Job script",
            .serde = .string(.print),
        },
    } ++ openapi.BaseResponseProperties,
};

pub const JobsResponse: SchemaComponent = .{
    .child = Jobs,
    .api_type = models.JobsResponse,
    .properties = [_]Property{
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
    } ++ openapi.BaseResponseProperties,
};

pub const SharedMembers: []const Property = &.{
    .{
        .name = "account",
        .description = "Name of the Account the Job runs under",
        .serde = .string(.native),
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
        .name = "batch_features",
        .description = "Batch Features requested by the Job",
        .serde = .string(.native),
    },
    .{
        .name = "burst_buffer",
        .description = "Burst Buffer Info",
        .serde = .string(.native),
    },
    .{
        .name = "cluster_features",
        .description = "Cluster features required by this Job",
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
        .name = "extra",
        .description = "Some extra information",
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
        .name = "licenses",
        .description = "Required Licenses",
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
        .name = "mcs_label",
        .description = "Multi-Category Security Label",
        .serde = .string(.native),
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
        .name = "wckey",
        .description = "Workload characzerization key",
        .serde = .string(.native),
    },
    .{
        .api_name = "work_dir",
        .name = "working_directory",
        .description = "Working Directory for the Job",
        .serde = .string(.native),
    },
    .{
        .api_name = "wait4switch",
        .name = "wait_for_switch",
        .description = "How long to wait for Switches",
        .serde = .integer(.native),
    },
    .{
        .name = "segment_size",
        .description = "Size of Segments with Block or Ring Topology",
        .serde = .integer(.native),
    },
    .{
        .api_name = "req_switch",
        .name = "required_switches",
        .description = "Number of required switches",
        .serde = .integer(.native),
    },
    .{
        .name = "selinux_context",
        .description = "SELinux Context",
        .serde = .string(.native),
    },
    .{
        .api_name = "pn_min_tmp_disk",
        .name = "temporary_disk_per_node",
        .description = "Temporary Disk Space required per Node",
        .serde = .integer(.native),
    },
    .{
        .api_name = "pn_min_cpus",
        .name = "min_cpus_per_node",
        .description = "Minimum CPUs per Node",
        .serde = .integer(.native),
    },
    .{
        .name = "cpus_per_task",
        .description = "CPUs Per Task requested",
        .serde = .integer(.native),
    },
    .{
        .name = "mem_per_tres",
        .description = "Memory per TRES",
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
        .name = "time_min",
        .description = "Minimum Time Limit",
        .serde = .object(.number_zero_is_noval),
    },
    .{
        .name = "time_limit",
        .description = "Time Limit",
        .serde = .object(.number_zero_is_noval),
    },
    .{
        .api_name = "requeue",
        .name = "requeueable",
        .description = "Whether the job can be requeued or not",
        .serde = .boolean(.int),
    },
    .{
        .name = "partition",
        .description = "Name of the Partition",
        .serde = .string(.native),
    },
    .{
        .name = "qos",
        .description = "Name of the QoS",
        .serde = .string(.native),
    },
    .{
        .api_name = "reboot",
        .name = "reboot_required",
        .description = "Whether the Job requires nodes being rebooted before starting",
        .serde = .boolean(.int),
    },
    .{
        .api_name = "prefer",
        .name = "preferred_features",
        .description = "Preferred List of features",
        .serde = .array(.csv),
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
        .name = "cpus_per_tres",
        .description = "CPUs per TRES",
        .serde = .dict(.key_value, &.{ .string, .integer }),
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
        .name = "features",
        .description = "Features requested by the Job",
        .serde = .array(.csv),
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
    .{
        .name = "group_id",
        .description = "Group ID of the user owning the Job",
        .serde = .integer(.native),
    },
    .{
        .name = "het_job_offset",
        .description = "Heterogenous Job Offset",
        .serde = .integer(.native_zero_is_noval),
    },
    .{
        .api_name = "user_id",
        .name = "user_name",
        .description = "Name of the User who submitted this Job",
        .serde = .string(.user_name),
    },
    .{
        .name = "name",
        .description = "Name of the Job",
        .serde = .string(.native),
    },
    .{
        .name = "network",
        .description = "Network specification",
        .serde = .string(.native),
    },
    // TODO: Properly dump/parse nice value - it has an offset
    .{
        .name = "nice",
        .description = "Nice value",
        .serde = .integer(.native),
    },
    .{
        .api_name = "num_tasks",
        .name = "ntasks",
        .description = "Total amount of Tasks for the Job",
        .serde = .integer(.native),
    },
    .{
        .name = "priority",
        .description = "Priority for the Job",
        .serde = .integer(.native),
    },
    .{
        .name = "profile",
        .description = "Profile types",
        .serde = .array(.bitflag),
    },
    .{
        .api_name = "req_nodes",
        .name = "required_nodes",
        .description = "Required Nodes",
        .serde = .string(.native),
    },
    .{
        .name = "shared",
        .description = "Job oversubscription",
        .serde = .string(.@"enum"),
    },
    .{
        .name = "site_factor",
        .description = "Site-specific priority factor",
        .serde = .integer(.native),
    },
    .{
        .name = "oom_kill_step",
        .description = "Whether to kill the whole Step if a Task goes OOM",
        .serde = .boolean(.int),
    },
};

pub const JobDescription: SchemaComponent = .{
    .api_type = slurm.JobSubmitDescription,
    .ignored_fields = &.{
        "argc", "array_bitmap",
    },
    .properties = SharedMembers ++ [_]Property{
        .{
            .api_name = "acctg_freq",
            .name = "accounting_gather_frequency",
            .description = "Job accounting sampling interval in seconds",
            .serde = .string(.native),
        },
        .{
            .api_name = "alloc_resp_port",
            .name = "allocation_node_port",
            .description = "To which port the allocation confirmation is sent",
            .serde = .integer(.native),
        },
        .{
            .name = "begin_time",
            .description = "How long, in seconds, to defer the allocation of Resources",
            .serde = .integer(.native_zero_is_noval),
        },
        .{
            .name = "array",
            .description = "Array Specification",
            .serde = .string(.native),
        },
        .{
            .name = "clusters",
            .description = "Clusters the Job may run on",
            .serde = .array(.csv),
        },
        .{
            .name = "min_cpus",
            .description = "Minimum number of CPUs required",
            .serde = .integer(.native),
        },
        .{
            .name = "max_cpus",
            .description = "Maximum number of CPUs required",
            .serde = .integer(.native),
        },
        .{
            .name = "min_nodes",
            .description = "Minimum number of Nodes required",
            .serde = .integer(.native),
        },
        .{
            .name = "max_nodes",
            .description = "Maximum number of Nodes required",
            .serde = .integer(.native),
        },
        // TODO:
//      .{
//          .name = "x11",
//          .description = "Maximum number of Nodes required",
//          .serde = .integer(.native),
//      },
        .{
            .name = "x11_magic_cookie",
            .description = "X11 Magic Cookie",
            .serde = .string(.native),
        },
        .{
            .api_name = "x11_target",
            .name = "x11_target_host",
            .description = "Hostname or UNIX socket if x11_target_port is 0",
            .serde = .string(.native),
        },
        .{
            .name = "x11_target_port",
            .description = "X11 Target Port",
            .serde = .integer(.native),
        },
        .{
            .name = "ntasks_per_tres",
            .description = "Number of tasks for each GPU",
            .serde = .integer(.native),
        },
        .{
            .name = "ntasks_per_board",
            .description = "Number of tasks to invoke on each board",
            .serde = .integer(.native),
        },
        .{
            .name = "ntasks_per_core",
            .description = "Number of tasks to invoke on each core",
            .serde = .integer(.native),
        },
        .{
            .name = "ntasks_per_socket",
            .description = "Number of tasks to invoke on each socket",
            .serde = .integer(.native),
        },
        .{
            .name = "ntasks_per_node",
            .description = "Number of tasks to invoke on each Node",
            .serde = .integer(.native),
        },
        .{
            .name = "threads_per_core",
            .description = "Number of Threads per Core required",
            .serde = .integer(.native),
        },
        .{
            .name = "sockets_per_node",
            .description = "Number of Sockets per Node required",
            .serde = .integer(.native),
        },
        .{
            .name = "sockets_per_board",
            .description = "Number of Sockets per Board required",
            .serde = .integer(.native),
        },
        .{
            .name = "boards_per_node",
            .description = "Number of Boards per Node required",
            .serde = .integer(.native),
        },
        .{
            .api_name = "warn_time",
            .name = "kill_warning_time",
            .description = "When a Job is within X seconds of its end time, send the signal",
            .serde = .integer(.native),
        },
        .{
            .api_name = "warn_signal",
            .name = "kill_warning_signal",
            .description = "Signal to send to a Job",
            .serde = .integer(.signal),
        },
        .{
            .api_name = "warn_flags",
            .name = "kill_warning_flags",
            .description = "Flags for Job signals",
            .serde = .array(.bitflag),
        },
        .{
            .name = "wait_all_nodes",
            .description = "Whether to wait to start until all nodes are booted",
            .serde = .boolean(.int),
        },
        .{
            .name = "reservation",
            .description = "Name of the Reservation to use",
            .serde = .string(.native),
        },
    },
};

pub const Job: SchemaComponent = .{
    .api_type = slurm.Job,
    .ignored_fields = &.{
        "node_inx", "priority_array", "req_node_inx", "exc_node_inx",
        "array_bitmap", "fed_siblings_active_str", "fed_siblings_viable_str",
        "job_size_str", "tres_bind", "tres_freq", "job_resrcs",
    },
    .properties = SharedMembers ++ [_]Property{
        .{
            .name = "accrue_time",
            .description = "Accrue time",
            .serde = .integer(.timestamp),
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
            .name = "command",
            .description = "sbatch Command",
            .serde = .string(.native),
        },
        .{
            .name = "billable_tres",
            .description = "Billable TRES",
            .serde = .integer(.std),
        },
        .{
            .name = "cronspec",
            .description = "Cron specification",
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
            .name = "exit_code",
            .description = "Exit code",
            .serde = .integer(.std),
        },
        .{
            .name = "failed_node",
            .description = "Node that caused the Job to fail",
            .serde = .string(.native),
        },
        .{
            .api_name = "fed_origin_str",
            .name = "federation_origin",
            .description = "Federation origin",
            .serde = .string(.native),
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
            .name = "licenses_allocated",
            .description = "Allocated Licenses",
            .serde = .array(.csv),
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
            .name = "threads_per_core",
            .description = "Threads per Core",
            .serde = .object(.number),
        },
        .{
            .api_name = "state_desc",
            .name = "state_description",
            .description = "State Description",
            .serde = .string(.native),
        },
        .{
            .name = "state_reason",
            .description = "Reason why the Job is in its current state",
            .serde = .string(.@"enum"),
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
            .api_name = "memoryTotal",
            .name = "memory_total",
            .description = "Total memory allocated or requested by the Job",
            .serde = .integer(.job_memory_total),
            .extra = true,
        },
        .{
            .api_name = "resv_name",
            .name = "reservation",
            .description = "Name of the Reservation used",
            .serde = .string(.native),
        },
        .{
            .name = "user_id",
            .description = "UID of the User who submitted this Job",
            .serde = .integer(.native),
        },
        .{
            .api_name = "job_id",
            .name = "id",
            .description = "ID of the Job",
            .serde = .integer(.native),
        },
        .{
            .name = "system_comment",
            .description = "System comment",
            .serde = .string(.native),
        },
        .{
            .api_name = "num_cpus",
            .name = "cpus",
            .description = "Total amount of CPUs for the Job",
            .serde = .integer(.native),
        },
        .{
            .api_name = "num_nodes",
            .name = "node_count",
            .description = "Total amount of Nodes for the Job",
            .serde = .integer(.native),
        },
        // TODO:: Properly parse mem-per-cpu vs mem-per-node
        .{
            .api_name = "pn_min_memory",
            .name = "mem_per_cpu",
            .description = "Memory per CPU",
            .serde = .integer(.native),
        },
        .{
            .api_name = "pn_min_memory",
            .name = "mem_per_node",
            .description = "Memory per Node",
            .serde = .integer(.native),
        },
        .{
            .name = "preempt_time",
            .description = "Preempt time",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "preemptable_time",
            .description = "Preemptable time",
            .serde = .integer(.timestamp),
        },
        // TODO:  Figure out what it is again...
        .{
            .name = "pre_sus_time",
            .description = "pre_sus_time",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "resize_time",
            .description = "Time when the Job was resized",
            .serde = .integer(.timestamp),
        },
        .{
            .api_name = "restart_cnt",
            .name = "restart_count",
            .description = "How often the Job already restarted",
            .serde = .integer(.native),
        },
        .{
            .api_name = "resv_ports",
            .name = "reserved_srun_ports",
            .description = "Reserved Ports for srun",
            .serde = .string(.native),
        },
        .{
            .api_name = "sched_nodes",
            .name = "nodes_scheduled",
            .description = "Nodes that the Job is scheduled to run on",
            .serde = .string(.native),
        },
        .{
            .name = "step_id",
            .description = "Step ID",
            .serde = .object(.container),
            .ref = openapi.StepID,
        },
        .{
            .name = "start_time",
            .description = "UNIX Timestamp of when the Job starts",
            .serde = .integer(.timestamp),
        },
        .{
            .api_name = "start_protocol_ver",
            .name = "start_protocol_version",
            .description = "Protocol version of Slurm the Job started with",
            .serde = .integer(.native),
        },
        .{
            .name = "submit_line",
            .description = "Sbatch submit line",
            .serde = .string(.native),
        },
        .{
            .name = "submit_time",
            .description = "UNIX Timestamp of when the Job was submitted",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "suspend_time",
            .description = "UNIX Timestamp of when the Job was suspended",
            .serde = .integer(.timestamp),
        },
    },
};

