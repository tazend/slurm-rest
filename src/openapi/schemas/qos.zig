const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const models = @import("../../models.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;

pub const QoS: SchemaComponent = .{
    .api_type = slurm.db.QoS,
    .properties = Base ++ Limits,
};

pub const QoSArray: SchemaComponent = .array(QoS, .list);
pub const Response = openapi.GenericResponse("QoSArray", "List of QoS");
pub const SingleResponse = openapi.GenericResponse("QoS", "Database QoS Information");

pub const Base: []const Property = &.{
    .{
        .name = "description",
        .description = "Arbitrary Description for the QoS",
        .serde = .string(.native),
    },
    .{
        .name = "flags",
        .description = "QoS Flags",
        .serde = .array(.bitflag),
    },
    .{
        .name = "id",
        .description = "Unique QoS ID",
        .serde = .integer(.native),
    },
    .{
        .name = "name",
        .description = "QoS Name",
        .serde = .string(.native),
    },
//  .{
//      .name = "preempt_list",
//      .description = "Preemption list",
//      .serde = .array(.list),
//  },
//  .{
//      .name = "preempt_mode",
//      .description = "Preemption Mode",
//      .serde = .array(.bitflag),
//  },
    .{
        .name = "preempt_exempt_time",
        .description = "Preempt exempt time",
        .serde = .integer(.native),
    },
    .{
        .name = "priority",
        .description = "Priority",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .name = "usage_factor",
        .description = "Usage Factor",
        .serde = .integer(.std),
    },
    .{
        .api_name = "usage_thres",
        .name = "usage_threshold",
        .description = "Usage Threshold",
        .serde = .integer(.std),
    },
};

pub const Limits: []const Property = &.{
    .{
        .name = "grace_time",
        .description = "Preemption grace time in seconds the job has time before being preempted",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "grp_jobs_accrue",
        .name = "group_jobs_accrue",
        .description = "Group Job Accrue",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "grp_jobs",
        .name = "group_jobs",
        .description = "Group Jobs",
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
        .name = "limit_factor",
        .description = "Limit factor",
        .serde = .integer(.std),
    },
    .{
        .api_name = "max_jobs_pa",
        .name = "max_jobs_per_account",
        .description = "Max Jobs per Account",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_jobs_pu",
        .name = "max_jobs_per_user",
        .description = "Max Jobs per Account",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_jobs_accrue_pa",
        .name = "max_jobs_accrue_per_account",
        .description = "Max Jobs Accrue per Account",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_jobs_accrue_pu",
        .name = "max_jobs_accrue_per_user",
        .description = "Max Jobs Accrue per Account",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_submit_jobs_pu",
        .name = "max_submit_jobs_per_user",
        .description = "Max Jobs submit per User",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_submit_jobs_pa",
        .name = "max_submit_jobs_per_account",
        .description = "Max Jobs submit per Account",
        .serde = .integer(.native_infinite_is_null),
    },
    .{
        .api_name = "max_tres_mins_pj",
        .name = "max_tres_minutes_per_job",
        .description = "Max tres minutes per Job",
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
        .api_name = "max_tres_pu",
        .name = "max_tres_per_user",
        .description = "Max tres per User",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_tres_pa",
        .name = "max_tres_per_account",
        .description = "Max tres per Account",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_tres_run_mins_pa",
        .name = "max_tres_run_minutes_per_account",
        .description = "Max tres run minutes per Account",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
    .{
        .api_name = "max_tres_run_mins_pu",
        .name = "max_tres_run_minutes_per_user",
        .description = "Max tres run minutes per User",
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
        .api_name = "min_tres_pj",
        .name = "min_tres_per_job",
        .description = "Min TRES per Job",
        .serde = .dict(.key_value, &.{ .integer, .string }),
    },
};
