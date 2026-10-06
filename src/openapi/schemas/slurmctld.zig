const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const ControllerStatisticsResponse: SchemaComponent = .{
    .api_type = models.ControllerStatisticsResponse,
    .properties = [_]Property{
        .{
            .name = "statistics",
            .description = "Controller statistics",
            .serde = .string(.print),
        },
    } ++ openapi.BaseResponseProperties,
};

pub const ControllerStatistics: SchemaComponent = .{
    .api_type = slurm.slurmctld.Statistics,
    .properties = &.{
        .{
            .api_name = "req_time",
            .name = "request_time",
            .description = "Time of request",
            .serde = .integer(.timestamp),
        },
        .{
            .api_name = "req_time_start",
            .name = "request_time_start",
            .description = "Time of request Start",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "server_thread_count",
            .description = "Number of active threads",
            .serde = .integer(.native),
        },
        .{
            .name = "agent_queue_size",
            .description = "Number of queued outgoing RPC requests",
            .serde = .integer(.native),
        },
        .{
            .name = "agent_count",
            .description = "Number of Agent threads",
            .serde = .integer(.native),
        },
        .{
            .name = "agent_thread_count",
            .description = "Total amount of threads created by all agent threads",
            .serde = .integer(.native),
        },
        .{
            .name = "dbd_agent_queue_size",
            .description = "Amount of messages queued for slurmdbd",
            .serde = .integer(.native),
        },
        .{
            .name = "gettimeofday_latency",
            .description = "Latency of 1000 calls to gettimeofday syscall, in microseconds",
            .serde = .integer(.native),
        },
        .{
            .name = "schedule_cycle_max",
            .description = "Max time of any scheduling cycle in microseconds, since last reset",
            .serde = .integer(.native),
        },
        .{
            .name = "schedule_cycle_last",
            .description = "Time in microseconds for last scheduling cycle",
            .serde = .integer(.native),
        },
        .{
            .name = "schedule_cycle_sum",
            .description = "Total run time of all scheduling cycles since last reset, in microseconds",
            .serde = .integer(.native),
        },
        .{
            .name = "schedule_cycle_sum",
            .description = "Total run time of all scheduling cycles since last reset, in microseconds",
            .serde = .integer(.native),
        },
        .{
            .api_name = "schedule_cycle_counter",
            .name = "schedule_cycles",
            .description = "Number of scheduling cycles since last reset",
            .serde = .integer(.native),
        },
        .{
            .api_name = "meanCycle",
            .name = "schedule_cycle_mean",
            .description = "Mean time for all scheduling cycles, in microseconds",
            .serde = .integer(.method_number_flat),
            .extra = true,
        },
        .{
            .api_name = "meanDepthCycle",
            .name = "schedule_cycle_mean_depth",
            .description = "Mean of number of jobs processed during scheduling",
            .serde = .integer(.method_number_flat),
            .extra = true,
        },
        .{
            .api_name = "cyclesPerMinute",
            .name = "schedule_cycleis_per_minute",
            .description = "Number of scheduling cycles performed per minute",
            .serde = .integer(.method_number_flat),
            .extra = true,
        },
        .{
            .name = "schedule_cycle_depth",
            .description = "Total amount of jobs processed during scheduling",
            .serde = .integer(.native),
        },
        // TODO:
//      .{
//          .name = "schedule_cycle_exit",
//          .description = "schedule exit fields",
//          .serde = .integer(.native),
//      },
        .{
            .api_name = "schedule_queue_len",
            .name = "schedule_queue_length",
            .description = "Number of Jobs pending in queue",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_submitted",
            .description = "Number of Jobs submitted",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_started",
            .description = "Number of Jobs started",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_completed",
            .description = "Number of Jobs completed",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_canceled",
            .description = "Number of Jobs canceled",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_failed",
            .description = "Number of Jobs failed",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_pending",
            .description = "Number of Jobs pending",
            .serde = .integer(.native),
        },
        .{
            .name = "jobs_running",
            .description = "Number of Jobs running",
            .serde = .integer(.native),
        },
        .{
            .api_name = "job_states_ts",
            .name = "job_states_timestamp",
            .description = "UNIX Timestamp",
            .serde = .integer(.timestamp),
        },
    },
};

