const std = @import("std");
const mem = std.mem;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const httpz = @import("httpz");
const RequestContext = @import("route.zig").RequestContext;
const RouteData = @import("route.zig").RouteData;
pub const ParameterParser = @This();

arena: std.mem.Allocator,
request: *httpz.Request,
qos: ?*slurm.List(*slurm.db.QoS) = null,
db_conn: ?*slurm.db.Connection = null,

pub fn init(ctx: *RequestContext, qos: ?*slurm.List(*slurm.db.QoS), db_conn: ?*slurm.db.Connection) ParameterParser {
    return .{
        .arena = ctx.arena,
        .request = ctx.req,
        .db_conn = db_conn,
        .qos = qos,
    };
}

pub const Style = enum {
    simple,
    form,
};

pub const ParserType = enum {
    list,
    list_qos_ids,
    flags,
    flags_int,
    string,
    integer,
    @"enum",
};

pub const Reference = struct {
    name: [:0]const u8,
    component: QueryParameterComponent,
};

pub const Parameter = struct {
    api_name: ?[:0]const u8 = null,
    name: [:0]const u8,
    description: []const u8,
    required: bool = false,
    style: Style = .form,
    explode: bool = true,
    parser: ParserType,

    pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
        try jw.beginObject();

        try jw.objectField("in");
        try jw.write("query");
        try jw.objectField("name");
        try jw.write(self.name);
        try jw.objectField("description");
        try jw.write(self.description);
        try jw.objectField("required");
        try jw.write(self.required);
        try jw.objectField("style");
        try jw.write(self.style);
        try jw.objectField("explode");
        try jw.write(self.explode);

        try jw.objectField("schema");
        try jw.beginObject();
        // TODO: Figure out the proper json type
        try jw.objectField("type");
        try jw.write("string");
        try jw.endObject();
        try jw.endObject();
    }
};

pub const QueryParameterComponent = struct {
    api_type: type,
    parameters: []const Parameter = &.{},
    refs: []const Reference = &.{},

    pub const init = parse;
};

pub const AssociationFlags: QueryParameterComponent = .{
    .api_type = slurm.db.Association.Flags,
    .parameters = &.{
        .{
            .api_name = "with_deleted",
            .name = "with_deleted",
            .description = "Whether to also show deleted Associations",
            .parser = .flags,
        },
        .{
            .api_name = "with_usage",
            .name = "with_usage",
            .description = "Whether to also include Usage",
            .parser = .flags,
        },
        .{
            .api_name = "only_defs",
            .name = "only_defaults",
            .description = "Whether to only show default Associations",
            .parser = .flags,
        },
        .{
            .api_name = "raw_qos",
            .name = "raw_qos",
            .description = "Include raw QoS",
            .parser = .flags,
        },
        .{
            .api_name = "sub_accts",
            .name = "sub_account",
            .description = "Include Sub Account Information",
            .parser = .flags,
        },
        .{
            .api_name = "wopi",
            .name = "without_parent_id",
            .description = "Exclude Parent ID",
            .parser = .flags,
        },
        .{
            .api_name = "wopl",
            .name = "without_parent_limits",
            .description = "Exclude Limits from Parents",
            .parser = .flags,
        },
        .{
            .api_name = "qos_usage",
            .name = "with_qos_usage",
            .description = "Include QoS Usage",
            .parser = .flags,
        },
    },
};

pub const Associations: QueryParameterComponent = .{
    .api_type = slurm.db.Association.Filter,
    .refs = &.{
        .{
            .name = "flags",
            .component = AssociationFlags,
        },
    },
    .parameters = &.{
        .{
            .api_name = "acct_list",
            .name = "accounts",
            .description = "Accounts to filter for",
            .parser = .list,
        },
        .{
            .api_name = "cluster_list",
            .name = "clusters",
            .description = "Clusters to filter for",
            .parser = .list,
        },
        .{
            .api_name = "def_qos_id_list",
            .name = "default_qos",
            .description = "Default QoS to filter for",
            .parser = .list,
        },
        .{
            .api_name = "id_list",
            .name = "ids",
            .description = "Association IDs to filter for",
            .parser = .list,
        },
        .{
            .api_name = "parent_acct_list",
            .name = "parent_accounts",
            .description = "Parent Accounts to filter for",
            .parser = .list,
        },
        .{
            .api_name = "partition_list",
            .name = "partitions",
            .description = "Partitions to filter for",
            .parser = .list,
        },
        .{
            .api_name = "qos_list",
            .name = "qos",
            .description = "QoS to filter for",
            .parser = .list_qos_ids,
        },
        .{
            .api_name = "user_list",
            .name = "users",
            .description = "Users to filter for",
            .parser = .list,
        },
    },
};

pub const UserAssocFilter: QueryParameterComponent = .{
    .api_type = slurm.db.Association.Filter,
    .parameters = &.{
        .{
            .api_name = "user_list",
            .name = "names",
            .description = "Filter for specific User Names",
            .parser = .list,
        },
    },
};

pub const Users: QueryParameterComponent = .{
    .api_type = slurm.db.User.Filter,
    .refs = &.{
        .{
            .name = "assoc_cond",
            .component = UserAssocFilter,
        },
    },
    .parameters = &.{
        .{
            .name = "admin_level",
            .description = "Admin Level to filter for",
            .parser = .@"enum",
        },
        .{
            .api_name = "def_acct_list",
            .name = "default_accounts",
            .description = "Default Accounts to filter for",
            .parser = .list,
        },
        .{
            .api_name = "def_wckey_list",
            .name = "default_wckeys",
            .description = "Default WCKeys to filter for",
            .parser = .list,
        },
        .{
            .api_name = "with_assocs",
            .name = "with_associations",
            .description = "Include Association Infos",
            .parser = .flags_int,
        },
        .{
            .api_name = "with_coords",
            .name = "with_coordinators",
            .description = "Include Coordinator Infos",
            .parser = .flags_int,
        },
        .{
            .name = "with_deleted",
            .description = "Include deleted Users",
            .parser = .flags_int,
        },
        .{
            .name = "with_wckeys",
            .description = "Include WCKeys",
            .parser = .flags_int,
        },
        .{
            .name = "without_defaults",
            .description = "Exclude Defaults",
            .parser = .flags_int,
        },
    },
};

pub const Accounts: QueryParameterComponent = .{
    .api_type = slurm.db.Account.Filter,
    .refs = &.{
        .{
            .name = "flags",
            .component = AccountFlags,
        },
        .{
            .name = "assoc_cond",
            .component = AccountAssocFilter,
        },
    },
    .parameters = &.{
        .{
            .api_name = "description_list",
            .name = "descriptions",
            .description = "Descriptions to filter for",
            .parser = .list,
        },
        .{
            .api_name = "organization_list",
            .name = "organizations",
            .description = "Organizations to filter for",
            .parser = .list,
        },
    },
};

pub const AccountFlags: QueryParameterComponent = .{
    .api_type = slurm.db.Account.Flags,
    .parameters = &.{
        .{
            .api_name = "deleted",
            .name = "with_deleted",
            .description = "Whether to also show deleted Accounts",
            .parser = .flags,
        },
        .{
            .api_name = "with_assocs",
            .name = "with_associations",
            .description = "Whether to also fetch Associations",
            .parser = .flags,
        },
        .{
            .api_name = "with_coords",
            .name = "with_coordinators",
            .description = "Whether to also fetch Coordinators",
            .parser = .flags,
        },
    },
};

pub const AccountAssocFilter: QueryParameterComponent = .{
    .api_type = slurm.db.Association.Filter,
    .parameters = &.{
        .{
            .api_name = "acct_list",
            .name = "names",
            .description = "Filter for specific Account Names",
            .parser = .list,
        },
    },
};

pub const QoSFlags: QueryParameterComponent = .{
    .api_type = slurm.QoSFlags,
    .parameters = &.{
        .{
            .api_name = "deleted",
            .name = "with_deleted",
            .description = "Whether to also show deleted QoS",
            .parser = .flags,
        },
    },
};

pub const QoS: QueryParameterComponent = .{
    .api_type = slurm.db.QoS.Filter,
    .refs = &.{
        .{
            .name = "flags",
            .component = QoSFlags,
        },
    },
    .parameters = &.{
        .{
            .api_name = "description_list",
            .name = "descriptions",
            .description = "Descriptions to filter for",
            .parser = .list,
        },
        .{
            .api_name = "id_list",
            .name = "ids",
            .description = "IDs to filter for",
            .parser = .list,
        },
        .{
            .api_name = "name_list",
            .name = "names",
            .description = "Names to filter for",
            .parser = .list,
        },
//      .{
//          .name = "preempt_mode",
//          .description = "Preempt Mode to filter for",
//          .parse = TODO,
//      },
    },
};

pub const JobFlags : QueryParameterComponent = .{
    .api_type = slurm.db.Job.Flags,
    .parameters = &.{
        .{
            .api_name = "duplicate",
            .name = "show_duplicates",
            .description = "Do not include duplicate Jobs",
            .parser = .flags,
        },
        .{
            .api_name = "no_truncate",
            .name = "truncate_usage_time",
            .description = "Truncate time to the Start and End Time",
            .parser = .flags,
        },
        .{
            .api_name = "script",
            .name = "show_batch_script",
            .description = "Fetch Batch script",
            .parser = .flags,
        },
        .{
            .api_name = "environment",
            .name = "show_environment",
            .description = "Fetch Job Environment",
            .parser = .flags,
        },
        .{
            .api_name = "no_step",
            .name = "skip_steps",
            .description = "Do not include Step Data",
            .parser = .flags,
        },
    },
};

pub const Job: QueryParameterComponent = .{
    .api_type = slurm.db.Job.Filter,
    .refs = &.{
        .{
            .name = "flags",
            .component = JobFlags,
        },
    },
    .parameters = &.{
        .{
            .api_name = "cluster_list",
            .name = "cluster",
            .description = "Name of the Cluster to filter",
            .parser = .list,
        },
        .{
            .api_name = "usage_start",
            .name = "start_time",
            .description = "Filter for Jobs which started at this UNIX Timestamp",
            .parser = .integer,
        },
        .{
            .api_name = "usage_end",
            .name = "end_time",
            .description = "Filter for Jobs which ended at this UNIX Timestamp",
            .parser = .integer,
        },
    },
};

pub const Jobs: QueryParameterComponent = .{
    .api_type = slurm.db.Job.Filter,
    .refs = &.{
        .{
            .name = "flags",
            .component = JobFlags,
        },
    },
    .parameters = &.{
        .{
            .api_name = "acct_list",
            .name = "account",
            .description = "Names of accounts to filter for",
            .parser = .list,
        },
        .{
            .api_name = "associd_list",
            .name = "association_id",
            .description = "Association ID to filter for",
            .parser = .list,
        },
        .{
            .api_name = "cluster_list",
            .name = "cluster",
            .description = "Name of the Cluster to filter",
            .parser = .list,
        },
        .{
            .api_name = "constraint_list",
            .name = "constraint",
            .description = "Filter for specific constraints",
            .parser = .list,
        },
        .{
            .api_name = "cpus_max",
            .name = "max_cpus",
            .description = "Filter for Jobs with at most this amount of CPUs",
            .parser = .integer,
        },
        .{
            .api_name = "cpus_min",
            .name = "min_cpus",
            .description = "Filter for Jobs with at least this amount of CPUs",
            .parser = .integer,
        },
//      .{
//          .api_name = "runaway",
//          .api_member = "flags",
//          .name = "only_runaway",
//          .description = "Only show runaway jobs",
//          .parse = flags,
//      },
        .{
            .api_name = "exitcode",
            .name = "exit_code",
            .description = "Filter for Jobs with this exit code",
            .parser = .integer,
        },
        .{
            .api_name = "groupid_list",
            .name = "group",
            .description = "Filter for Jobs submitted by this Group ID",
            .parser = .list,
        },
        .{
            .api_name = "jobname_list",
            .name = "name",
            .description = "Filter for Jobs with this Name",
            .parser = .list,
        },
        .{
            .api_name = "nodes_max",
            .name = "max_nodes",
            .description = "Filter for Jobs with at most this amount of Nodes",
            .parser = .integer,
        },
        .{
            .api_name = "nodes_min",
            .name = "min_nodes",
            .description = "Filter for Jobs with at least this amount of Nodes",
            .parser = .integer,
        },
        .{
            .api_name = "partition_list",
            .name = "partitition",
            .description = "Filter for Jobs with this Partition",
            .parser = .list,
        },
        .{
            .api_name = "qos_list",
            .name = "qos",
            .description = "Filter for Jobs with this QoS",
            .parser = .list,
        },
        .{
            .api_name = "reason_list",
            .name = "reason",
            .description = "Filter for Jobs with this Reason",
            .parser = .list,
        },
        .{
            .api_name = "resv_list",
            .name = "reservation",
            .description = "Filter for Jobs with this Reservation",
            .parser = .list,
        },
        .{
            .api_name = "state_list",
            .name = "state",
            .description = "Filter for Jobs with this State",
            .parser = .list,
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
            .parser = .integer,
        },
        .{
            .api_name = "timelimit_min",
            .name = "min_time_limit",
            .description = "Filter for Jobs with at least this time limit",
            .parser = .integer,
        },
        .{
            .api_name = "used_nodes",
            .name = "node",
            .description = "Filter for Jobs running on these nodes",
            .parser = .string,
        },
        .{
            .api_name = "userid_list",
            .name = "user",
            .description = "Filter for Jobs submitted by this User",
            .parser = .list,
        },
        .{
            .api_name = "wckey_list",
            .name = "wckey",
            .description = "Filter for Jobs with this WCKey",
            .parser = .list,
        },
        .{
            .api_name = "usage_start",
            .name = "start_time",
            .description = "Filter for Jobs which started at this UNIX Timestamp",
            .parser = .integer,
        },
        .{
            .api_name = "usage_end",
            .name = "end_time",
            .description = "Filter for Jobs which ended at this UNIX Timestamp",
            .parser = .integer,
        },
    },
};

pub fn initType(comptime T: type, arena: std.mem.Allocator) !T {
    switch (@typeInfo(T)) {
        .optional => |o| return try initType(o.child, arena),
        .pointer => |p| {
            const x = try arena.create(p.child);
            x.* = try initType(p.child, arena);
            return x;
        },
        .@"struct" => return .{},
        else => @compileError("Unsupported Type"),
    }
}

pub fn parse(self: *ParameterParser, comptime T: QueryParameterComponent) !T.api_type {
    var f: T.api_type = .{};
    var query = try self.request.query();
    var query_it = query.iterator();
    var refs_inited: [T.refs.len]bool = @splat(false);

    next: while (query_it.next()) |kv| {
        inline for (T.parameters) |param| {
            if (std.mem.eql(u8, kv.key, param.name)) {
                try self.parseParam(&f, kv.value, param);
                continue :next;
            }
        }
        inline for (T.refs, 0..) |ref, i| {
            const r = &@field(f, ref.name);
            const RefType = @TypeOf(r.*);

            if (!refs_inited[i]) {
                r.* = try initType(RefType, self.arena);
                refs_inited[i] = true;
            }

            const real = if (@typeInfo(RefType) == .optional)
                // Assume the unwrapped optional is a pointer for now
                r.*.?
            else
                r;

            inline for (ref.component.parameters) |param| {
                if (std.mem.eql(u8, kv.key, param.name)) {
                    try self.parseParam(real, kv.value, param);
                    continue :next;
                }
            }
        }
        return error.InvalidQueryParameter;
    }
    return f;
}

fn isInteger(s: []const u8) bool {
    _ = std.fmt.parseInt(usize, s, 10) catch return false;
    return true;
}

fn ensureQoSLoaded(self: *ParameterParser) !void {
    if (self.qos == null) {
        if (self.db_conn == null) self.db_conn = try slurm.db.Connection.open();
        self.qos = try slurm.db.qos.load(self.db_conn.?, .{});
    }
}

fn qosNameToId(qos: *slurm.List(*slurm.db.QoS), name: []const u8) ?u32 {
    var it = qos.iter();
    defer it.deinit();

    while (it.next()) |i| {
        const n = slurm.parseCStr(i.name) orelse continue;
        if (std.mem.eql(u8, n, name)) return i.id;
    } else return null;
}

pub fn parseParam(self: *ParameterParser, r: anytype, value: []const u8, comptime P: Parameter) anyerror!void {
    const fname = P.api_name orelse P.name;
    const field = &@field(r, fname);

    const T = @TypeOf(field.*);
    switch (P.parser) {
        .string => {
            const v = try self.arena.dupeZ(u8, value);
            field.* = v;
        },
        .integer => field.* = std.fmt.parseInt(T, value, 10) catch return error.InvalidNumber,
        .@"enum" => field.* = std.meta.stringToEnum(T, value) orelse return error.InvalidEnumValue,
        .flags, .flags_int => {
            if (std.mem.eql(u8, value, "true")) {
                field.* = if (P.parser == .flags) true else 1;
            } else if (std.mem.eql(u8, value, "false")) {
                field.* = if (P.parser == .flags) false else 0;
            } else return error.InvalidBooleanValue;
        },
        .list => {
            if (field.* == null) field.* = .initNoDestroyItems();
            const item = try self.arena.dupeZ(u8, value);
            field.*.?.append(item);

        },
        .list_qos_ids => {
            if (field.* == null) field.* = .initNoDestroyItems();

            const value_fmt = if (!isInteger(value)) blk: {
                try self.ensureQoSLoaded();
                if (qosNameToId(self.qos.?, value)) |id|
                    break :blk try std.fmt.allocPrintSentinel(self.arena, "{d}", .{id}, 0)
                else
                    // NOTE: Maybe Error on invalid QoS?
                    break :blk try self.arena.dupeZ(u8, value);
            } else try self.arena.dupeZ(u8, value);

            field.*.?.append(value_fmt);
        },
    }
}
