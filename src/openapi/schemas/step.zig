const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const Steps: SchemaComponent = .array(Step, .load_response);

pub const StepsResponse: SchemaComponent = .{
    .child = Steps,
    .api_type = models.StepsResponse,
    .properties = [_]Property{
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
    } ++ openapi.BaseResponseProperties,
};

pub const StepID: SchemaComponent = .{
    .api_type = slurm.Step.ID,
    .properties = &.{
        .{
            .api_name = "parseSluid",
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
            .api_name = "toStrBuf",
            .name = "step_id",
            .description = "Step ID",
            .serde = .string(.step_id),
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
            .ref = StepID,
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
            // TODO: Just specify the name of the field for api_name thatr contains the uid
            .api_name = "user_id",
            .name = "user_name",
            .description = "User Name for the Step",
            .serde = .string(.user_name),
        },
    },
};
