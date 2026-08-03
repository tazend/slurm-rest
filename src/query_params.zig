const std = @import("std");
const mem = std.mem;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const httpz = @import("httpz");
const RequestContext = @import("route.zig").RequestContext;
const baseType = @import("json/Dumper.zig").baseType;

const Parser = *const fn(target: anytype, value: [:0]const u8, comptime ctx: Context) anyerror!void;

pub const Style = enum {
    simple,
    form,
};

pub const Context = struct {
    field_name: [:0]const u8,
    api_member: ?[:0]const u8 = null,
};

pub const Parameter = struct {
    api_name: ?[:0]const u8 = null,
    api_member: ?[:0]const u8 = null,
    api_type: ?type = null,
    parse: Parser,
    name: [:0]const u8,
    description: []const u8,
    required: bool = false,
    style: Style = .form,
    explode: bool = true,
};

pub const QueryParameterComponent = struct {
    api_type: type,
    parameters: []const Parameter = &.{},

    pub const init = parse;
};

pub const Associations: QueryParameterComponent = .{
    .api_type = slurm.db.Association.Filter,
    .parameters = &.{
        .{
            .api_name = "acct_list",
            .name = "accounts",
            .description = "Accounts to filter for",
            .parse = list,
        },
        .{
            .api_name = "cluster_list",
            .name = "clusters",
            .description = "Clusters to filter for",
            .parse = list,
        },
        .{
            .api_name = "def_qos_id_list",
            .name = "default_qos",
            .description = "Default QoS to filter for",
            .parse = list,
        },
        .{
            .api_name = "id_list",
            .name = "ids",
            .description = "Association IDs to filter for",
            .parse = list,
        },
        .{
            .api_name = "parent_acct_list",
            .name = "parent_accounts",
            .description = "Parent Accounts to filter for",
            .parse = list,
        },
        .{
            .api_name = "partition_list",
            .name = "partitions",
            .description = "Partitions to filter for",
            .parse = list,
        },
        .{
            .api_name = "qos_list",
            .name = "qos",
            .description = "QoS to filter for",
            .parse = list,
        },
        .{
            .api_name = "user_list",
            .name = "users",
            .description = "Users to filter for",
            .parse = list,
        },
        .{
            .api_member = "flags",
            .name = "with_deleted",
            .description = "Whether to also show deleted Associations",
            .parse = flags,
        },
        .{
            .api_member = "flags",
            .name = "with_usage",
            .description = "Whether to also include Usage",
            .parse = flags,
        },
        .{
            .api_name = "only_defs",
            .api_member = "flags",
            .name = "only_defaults",
            .description = "Whether to only show default Associations",
            .parse = flags,
        },
        .{
            .api_member = "flags",
            .name = "raw_qos",
            .description = "Include raw QoS",
            .parse = flags,
        },
        .{
            .api_name = "sub_accts",
            .api_member = "flags",
            .name = "sub_account",
            .description = "Include Sub Account Information",
            .parse = flags,
        },
        .{
            .api_name = "wopi",
            .api_member = "flags",
            .name = "without_parent_id",
            .description = "Exclude Parent ID",
            .parse = flags,
        },
        .{
            .api_name = "wopl",
            .api_member = "flags",
            .name = "without_parent_limits",
            .description = "Exclude Limits from Parents",
            .parse = flags,
        },
        .{
            .api_name = "qos_usage",
            .api_member = "flags",
            .name = "with_qos_usage",
            .description = "Include QoS Usage",
            .parse = flags,
        },
    },
};

pub const Users: QueryParameterComponent = .{
    .api_type = slurm.db.User.Filter,
    .parameters = &.{
        .{
            .name = "admin_level",
            .description = "Admin Level to filter for",
            .parse = enu,
        },
        .{
            .api_name = "def_acct_list",
            .name = "default_accounts",
            .description = "Default Accounts to filter for",
            .parse = list,
        },
        .{
            .api_name = "def_wckey_list",
            .name = "default_wckeys",
            .description = "Default WCKeys to filter for",
            .parse = list,
        },
        .{
            .api_name = "with_assocs",
            .name = "with_associations",
            .description = "Include Association Infos",
            .parse = flagInt,
        },
        .{
            .api_name = "with_coords",
            .name = "with_coordinators",
            .description = "Include Coordinator Infos",
            .parse = flagInt,
        },
        .{
            .name = "with_deleted",
            .description = "Include deleted Users",
            .parse = flagInt,
        },
        .{
            .name = "with_wckeys",
            .description = "Include WCKeys",
            .parse = flagInt,
        },
        .{
            .name = "without_defaults",
            .description = "Exclude Defaults",
            .parse = flagInt,
        },
        .{
            .api_name = "user_list",
            .api_member = "assoc_cond",
            .name = "names",
            .description = "Filter for specific User Names",
            .parse = SubFilterParser(list),
        },
    },
};

pub const Accounts: QueryParameterComponent = .{
    .api_type = slurm.db.Account.Filter,
    .parameters = &.{
        .{
            .api_name = "description_list",
            .name = "descriptions",
            .description = "Descriptions to filter for",
            .parse = list,
        },
        .{
            .api_name = "organization_list",
            .name = "organizations",
            .description = "Organizations to filter for",
            .parse = list,
        },
        .{
            .api_name = "deleted",
            .api_member = "flags",
            .name = "with_deleted",
            .description = "Whether to also show deleted Accounts",
            .parse = flags,
        },
        .{
            .api_name = "with_assocs",
            .api_member = "flags",
            .name = "with_associations",
            .description = "Whether to also fetch Associations",
            .parse = flags,
        },
        .{
            .api_name = "with_coords",
            .api_member = "flags",
            .name = "with_coordinators",
            .description = "Whether to also fetch Coordinators",
            .parse = flags,
        },
        .{
            .api_name = "acct_list",
            .api_member = "assoc_cond",
            .name = "names",
            .description = "Filter for specific Account Names",
            .parse = SubFilterParser(list),
        },
    },
};

pub const QoS: QueryParameterComponent = .{
    .api_type = slurm.db.QoS.Filter,
    .parameters = &.{
        .{
            .api_name = "description_list",
            .name = "descriptions",
            .description = "Descriptions to filter for",
            .parse = list,
        },
        .{
            .api_name = "deleted",
            .api_member = "flags",
            .name = "with_deleted",
            .description = "Whether to also show deleted QoS",
            .parse = flags,
        },
        .{
            .api_name = "id_list",
            .name = "ids",
            .description = "IDs to filter for",
            .parse = list,
        },
        .{
            .api_name = "name_list",
            .name = "names",
            .description = "Names to filter for",
            .parse = list,
        },
//      .{
//          .name = "preempt_mode",
//          .description = "Preempt Mode to filter for",
//          .parse = TODO,
//      },
    },
};

pub const Job: QueryParameterComponent = .{
    .api_type = slurm.db.Job.Filter,
    .parameters = &.{
        .{
            .api_name = "cluster_list",
            .name = "cluster",
            .description = "Name of the Cluster to filter",
            .parse = list,
        },
        .{
            .api_name = "duplicate",
            .api_member = "flags",
            .name = "show_duplicates",
            .description = "Do not include duplicate Jobs",
            .parse = flags,
        },
        .{
            .api_name = "no_truncate",
            .api_member = "flags",
            .name = "truncate_usage_time",
            .description = "Truncate time to the Start and End Time",
            .parse = flags,
        },
        .{
            .api_name = "usage_start",
            .name = "start_time",
            .description = "Filter for Jobs which started at this UNIX Timestamp",
            .parse = number,
        },
        .{
            .api_name = "usage_end",
            .name = "end_time",
            .description = "Filter for Jobs which ended at this UNIX Timestamp",
            .parse = number,
        },
        .{
            .api_name = "script",
            .api_member = "flags",
            .name = "show_batch_script",
            .description = "Fetch Batch script",
            .parse = flags,
        },
        .{
            .api_name = "environment",
            .api_member = "flags",
            .name = "show_environment",
            .description = "Fetch Job Environment",
            .parse = flags,
        },
    },
};

pub const Jobs: QueryParameterComponent = .{
    .api_type = slurm.db.Job.Filter,
    .parameters = &.{
        .{
            .api_name = "acct_list",
            .name = "account",
            .description = "Names of accounts to filter for",
            .parse = list,
        },
        .{
            .api_name = "associd_list",
            .name = "association_id",
            .description = "Association ID to filter for",
            .parse = list,
        },
        .{
            .api_name = "cluster_list",
            .name = "cluster",
            .description = "Name of the Cluster to filter",
            .parse = list,
        },
        .{
            .api_name = "constraint_list",
            .name = "constraint",
            .description = "Filter for specific constraints",
            .parse = list,
        },
        .{
            .api_name = "cpus_max",
            .name = "max_cpus",
            .description = "Filter for Jobs with at most this amount of CPUs",
            .parse = number,
        },
        .{
            .api_name = "cpus_min",
            .name = "min_cpus",
            .description = "Filter for Jobs with at least this amount of CPUs",
            .parse = number,
        },
        .{
            .api_name = "duplicate",
            .api_member = "flags",
            .name = "show_duplicates",
            .description = "Do not include duplicate Jobs",
            .parse = flags,
        },
        .{
            .api_name = "no_step",
            .api_member = "flags",
            .name = "skip_steps",
            .description = "Do not include Step Data",
            .parse = flags,
        },
        .{
            .api_name = "no_truncate",
            .api_member = "flags",
            .name = "truncate_usage_time",
            .description = "Truncate time to the Start and End Time",
            .parse = flags,
        },
//      .{
//          .api_name = "runaway",
//          .api_member = "flags",
//          .name = "only_runaway",
//          .description = "Only show runaway jobs",
//          .parse = flags,
//      },
        .{
            .api_name = "script",
            .api_member = "flags",
            .name = "show_batch_script",
            .description = "Fetch Batch script",
            .parse = flags,
        },
        .{
            .api_name = "environment",
            .api_member = "flags",
            .name = "show_environment",
            .description = "Fetch Job Environment",
            .parse = flags,
        },
        .{
            .api_name = "exitcode",
            .name = "exit_code",
            .description = "Filter for Jobs with this exit code",
            .parse = number,
        },
        .{
            .api_name = "groupid_list",
            .name = "group",
            .description = "Filter for Jobs submitted by this Group ID",
            .parse = list,
        },
        .{
            .api_name = "jobname_list",
            .name = "name",
            .description = "Filter for Jobs with this Name",
            .parse = list,
        },
        .{
            .api_name = "nodes_max",
            .name = "max_nodes",
            .description = "Filter for Jobs with at most this amount of Nodes",
            .parse = number,
        },
        .{
            .api_name = "nodes_min",
            .name = "min_nodes",
            .description = "Filter for Jobs with at least this amount of Nodes",
            .parse = number,
        },
        .{
            .api_name = "partition_list",
            .name = "partitition",
            .description = "Filter for Jobs with this Partition",
            .parse = list,
        },
        .{
            .api_name = "qos_list",
            .name = "qos",
            .description = "Filter for Jobs with this QoS",
            .parse = list,
        },
        .{
            .api_name = "reason_list",
            .name = "reason",
            .description = "Filter for Jobs with this Reason",
            .parse = list,
        },
        .{
            .api_name = "resv_list",
            .name = "reservation",
            .description = "Filter for Jobs with this Reservation",
            .parse = list,
        },
        .{
            .api_name = "state_list",
            .name = "state",
            .description = "Filter for Jobs with this State",
            .parse = list,
        },
//      .{
//          .api_name = "step_list",
//          .name = "step",
//          .description = "Filter for Jobs with this Step",
//          .parse = list,
//      },
        .{
            .api_name = "timelimit_max",
            .name = "max_time_limit",
            .description = "Filter for Jobs with at most this time limit",
            .parse = number,
        },
        .{
            .api_name = "timelimit_min",
            .name = "min_time_limit",
            .description = "Filter for Jobs with at least this time limit",
            .parse = number,
        },
        .{
            .api_name = "used_nodes",
            .name = "node",
            .description = "Filter for Jobs running on these nodes",
            .parse = string,
        },
        .{
            .api_name = "userid_list",
            .name = "user",
            .description = "Filter for Jobs submitted by this User",
            .parse = list,
        },
        .{
            .api_name = "wckey_list",
            .name = "wckey",
            .description = "Filter for Jobs with this WCKey",
            .parse = list,
        },
        .{
            .api_name = "usage_start",
            .name = "start_time",
            .description = "Filter for Jobs which started at this UNIX Timestamp",
            .parse = number,
        },
        .{
            .api_name = "usage_end",
            .name = "end_time",
            .description = "Filter for Jobs which ended at this UNIX Timestamp",
            .parse = number,
        },
    },
};

pub fn parse(comptime T: QueryParameterComponent, ctx: *RequestContext) !T.api_type {
    var f: T.api_type = .{};
    var query = try ctx.req.query();
    var query_it = query.iterator();
    next: while (query_it.next()) |kv| {
        inline for (T.parameters) |param| {
            const parse_ctx: Context = comptime .{
                .field_name = param.api_name orelse param.name,
                .api_member = param.api_member,
            };
            if (std.mem.eql(u8, kv.key, param.name)) {
                const value = try ctx.arena.dupeZ(u8, kv.value);
                try param.parse(&f, value, parse_ctx);
                continue :next;
            }
        }
        return error.InvalidQueryParameter;
    }
    return f;
}

pub fn string(target: anytype, value: [:0]const u8, comptime ctx: Context) !void {
    @field(target, ctx.field_name) = value;
}

pub fn number(target: anytype, value: [:0]const u8, comptime ctx: Context) !void {
    const val = &@field(target, ctx.field_name);
    const T = @TypeOf(val.*);
    val.* = std.fmt.parseInt(T, value, 10) catch return error.InvalidNumber;
}

pub fn enu(target: anytype, value: [:0]const u8, comptime ctx: Context) !void {
    const val = &@field(target, ctx.field_name);
    const T = @TypeOf(val.*);
    val.* = std.meta.stringToEnum(T, value) orelse return error.InvalidAdminLevel;
}

pub fn flagInt(target: anytype, value: [:0]const u8, comptime ctx: Context) !void {
    if (std.mem.eql(u8, value, "true")) {
        @field(target, ctx.field_name) = 1;
    } else if (std.mem.eql(u8, value, "false")) {
        @field(target, ctx.field_name) = 0;
    } else return error.InvalidBooleanValue;
}

pub fn flags(target: anytype, value: [:0]const u8, comptime ctx: Context) !void {
    var t = if (ctx.api_member) |m| @field(target, m) else target;
    defer {
        if (ctx.api_member) |m| @field(target, m) = t;
    }

    if (std.mem.eql(u8, value, "true")) {
        @field(t, ctx.field_name) = true;
    } else if (std.mem.eql(u8, value, "false")) {
        @field(t, ctx.field_name) = false;
    } else return error.InvalidBooleanValue;
}

pub fn list(target: anytype, value: [:0]const u8, comptime ctx: Context) !void {
    const current = @field(target, ctx.field_name);
    if (current == null) {
        @field(target, ctx.field_name) = .initNoDestroyItems();
    }
    @field(target, ctx.field_name).?.append(value);
}

pub fn SubFilterParser(comptime parser: Parser) Parser {
    const H = struct {
        fn handle(target: anytype, value: [:0]const u8, comptime ctx: Context) anyerror!void {
            var current = @field(target, ctx.api_member.?) ;
            defer @field(target, ctx.api_member.?) = current;
            const T = @TypeOf(current);
            if (current == null) {
                current = try slurm.slurm_allocator.create(comptime baseType(T));
                current.?.* = .{};
            }
            try parser(current.?, value, ctx);
        }
    };
    return &H.handle;
}
