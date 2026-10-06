const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = @import("../../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const DBJobs: SchemaComponent = .array(DBJob, .list);
pub const DBJobsResponse = openapi.GenericResponse("DBJobs", "List of Database Jobs");
pub const DBJobResponse = openapi.GenericResponse("DBJob", "Database Job Information");

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
            .ref = openapi.DBSteps,
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

