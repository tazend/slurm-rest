const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../../openapi.zig");
const models = @import("../../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const DBSteps: openapi.SchemaComponent = .array(DBStep, .list);
pub const DBStepsResponse = openapi.GenericResponse("DBSteps", "List of Database Steps");

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
            .ref = openapi.StepID,
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

