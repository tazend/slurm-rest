const std = @import("std");
const mem = std.mem;
const slurm = @import("slurm");
const Stringify = std.json.Stringify;
const json = @import("../json.zig");
const parse = @import("parse.zig");
const ser = parse;
const NumberOptions = parse.NumberOptions;
const CStr = slurm.common.CStr;

pub fn baseType(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .optional, .pointer => blk: {
            const C = std.meta.Child(T);
            switch (@typeInfo(C)) {
                .pointer => break :blk std.meta.Child(C),
                else => break :blk C,
            }
        },
        else => T,
    };
}

pub fn find(comptime T: type) SlurmType {
    const decls = @typeInfo(@This()).@"struct".decls;
    const Child = comptime baseType(T);

    for (decls) |decl| {
        const field = @field(@This(), decl.name);
        if (@TypeOf(field) == SlurmType and field.typ == Child) {
            return field;
        }
    }
    return .default;
}

pub const Serialize = *const fn(*Stringify, anytype, anytype, anytype) anyerror!void;

pub const SlurmType = struct {
    typ: type,
    serializer: Serialize = ser.container,
    options: []const Option = &.{},
    extra_members: []const Option = &.{},
    default_member_serializer_args: ?*const anyopaque = null,

    /// Special serialization for selected fields.
    pub const Option = struct {
        name: [:0]const u8,
        new_name: ?[:0]const u8 = null,
        serializer: Serialize = ser.memberDefault,
        serializer_args: ?*const anyopaque = null,
    };

    pub const default: SlurmType = .{
        .typ = undefined,
        .serializer = ser.default,
    };
};

pub const AssociationShort = struct {
    account: ?CStr,
    cluster: ?CStr,
    partition: ?CStr,
    user: ?CStr,
    id: u32,
};

pub const Node: SlurmType = .{
    .typ = slurm.Node,
    .options = &.{
        .{ .name = "tres_fmt_str", .new_name = "tres", .serializer = ser.dict },
        .{ .name = "partitions", .serializer = ser.array },
        .{ .name = "features_act", .new_name = "features_active", .serializer = ser.array },
        .{ .name = "features", .new_name = "features_configured", .serializer = ser.array },
        .{ .name = "cpus_efctv", .new_name = "effective_cpus" },
        .{ .name = "core_spec_cnt", .new_name = "specialized_cpus" },
        .{ .name = "alloc_tres_fmt_str", .new_name = "alloc_tres", .serializer = ser.dict },
        .{ .name = "owner", .serializer = ser.numberFlat },
        .{ .name = "reason_uid", .serializer = ser.numberFlat },
        .{ .name = "resv_name", .new_name = "reservation" },
        // INFO: Can it really be NO_VAL64?
        .{ .name = "free_mem", .new_name = "free_memory" },
        .{ .name = "node_hostname", .new_name = "hostname" },
        .{ .name = "node_addr", .new_name = "address" },
        .{ .name = "cpu_spec_list", .new_name = "specialized_cpu_ids", .serializer = ser.arrayInt },
        .{ .name = "energy", .serializer = ser.container },

        // TODO: Proper GRES Parsing into Dict
        .{ .name = "gres", .serializer = ser.gresDict },
        .{ .name = "gres_used", .serializer = ser.array },
        .{ .name = "gres_drain", .new_name = "gres_drained", .serializer = ser.gresDict },

        .{ .name = "mem_spec_limit", .new_name = "specialized_memory" },
        .{ .name = "next_state", .new_name = "next_state_after_reboot", .serializer = ser.nodeNextState },
        .{ .name = "os", .new_name = "operating_system" },

        .{ .name = "reason_uid", .new_name = "reason_uid" },
        .{ .name = "tmp_disk", .new_name = "temporary_disk" },
        .{ .name = "topology_str", .new_name = "topology" },
    },
    .extra_members = &.{
        .{ .name = "idle_cpus", .serializer = ser.nodeIdleCpus },
        .{ .name = "reason_user", .serializer = ser.nodeReasonUser },
    }
};

pub const AccountingGatherEnergy: SlurmType = .{
    .typ = slurm.AccountingGatherEnergy,
    .options = &.{
        .{ .name = "slurmd_start_time", .serializer = ser.noop },
    },
};

pub const UserList: SlurmType = .{
    .typ = slurm.db.List(*slurm.db.User),
    .serializer = ser.list,
};

pub const WCKeyList: SlurmType = .{
    .typ = slurm.db.List(*slurm.db.WCKey),
    .serializer = ser.list,
};

pub const CoordinatorList: SlurmType = .{
    .typ = slurm.db.List(*slurm.db.Coordinator),
    .serializer = ser.list,
};

pub const User: SlurmType = .{
    .typ = slurm.db.User,
    .options = &.{
        .{ .name = "wckey_list", .new_name = "wckeys" },
        .{ .name = "coord_accts", .new_name = "coordinators", },
        .{ .name = "assoc_list", .new_name = "associations", .serializer = ser.assocsShort },
        .{ .name = "def_qos_id", .new_name = "default_qos" },
    },
};

pub const WCKey: SlurmType = .{
    .typ = slurm.db.WCKey,
    .options = &.{
        .{ .name = "accounting_list", .serializer = ser.noop },
    },
};

pub const Coordinator: SlurmType = .{
    .typ = slurm.db.Coordinator,
    .options = &.{
        .{ .name = "direct", .serializer = ser.bool },
    },
};

pub const ControllerStatistics: SlurmType = .{
    .typ = slurm.slurmctld.Statistics,
    .options = &.{
        .{ .name = "schedule_exit", .serializer = ser.noop },
        .{ .name = "bf_exit", .serializer = ser.noop },
        .{ .name = "rpc_type_id", .serializer = ser.noop },
        .{ .name = "rpc_type_cnt", .serializer = ser.noop },
        .{ .name = "rpc_type_time", .serializer = ser.noop },
        .{ .name = "rpc_type_queued", .serializer = ser.noop },
        .{ .name = "rpc_type_dropped", .serializer = ser.noop },
        .{ .name = "rpc_type_cycle_last", .serializer = ser.noop },
        .{ .name = "rpc_type_cycle_max", .serializer = ser.noop },
        .{ .name = "rpc_user_id", .serializer = ser.noop },
        .{ .name = "rpc_user_cnt", .serializer = ser.noop },
        .{ .name = "rpc_user_time", .serializer = ser.noop },
        .{ .name = "rpc_queue_type_id", .serializer = ser.noop },
        .{ .name = "rpc_queue_count", .serializer = ser.noop },
        .{ .name = "rpc_dump_types", .serializer = ser.noop },
        .{ .name = "rpc_dump_hostlist", .serializer = ser.noop },
    },
};

pub const Reservation: SlurmType = .{
    .typ = slurm.Reservation,
    .options = &.{
        .{ .name = "node_inx", .serializer = ser.noop },
        .{ .name = "core_spec_cnt", .serializer = ser.noop },
        .{ .name = "core_spec", .new_name = "specialized_cores", .serializer = ser.resCoreSpec },
        .{ .name = "tres_str", .new_name = "tres", .serializer = ser.dict },
        .{ .name = "node_cnt", .new_name = "node_count" },
        .{ .name = "node_list", .new_name = "nodes" },
        .{ .name = "licenses", .serializer = ser.array },
        .{ .name = "groups", .serializer = ser.array },
        .{ .name = "features", .serializer = ser.array },
        .{ .name = "allowed_parts", .serializer = ser.array },
        .{ .name = "accounts", .serializer = ser.array },
        .{ .name = "users", .serializer = ser.array },
    },
};

pub const Job: SlurmType = .{
    .typ = slurm.Job,
    .options = &.{
        .{ .name = "pn_min_memory", .new_name = "memory", .serializer = ser.jobMemory },
        .{ .name = "node_inx", .serializer = ser.noop },
        .{ .name = "priority_array", .serializer = ser.noop },
        .{ .name = "req_node_inx", .serializer = ser.noop },
        .{ .name = "exc_node_inx", .serializer = ser.noop },
        .{ .name = "array_bitmap", .serializer = ser.noop },
        .{ .name = "tres_req_str", .new_name = "tres_requested", .serializer = ser.dict },
        .{ .name = "tres_alloc_str", .new_name = "tres_allocated", .serializer = ser.dict },
        .{ .name = "tres_per_job", .serializer = ser.dict },
        .{ .name = "tres_per_node", .serializer = ser.dict },
        .{ .name = "tres_per_socket", .serializer = ser.dict },
        .{ .name = "tres_per_task", .serializer = ser.dict },
        .{ .name = "threads_per_core", .serializer = ser.number },
        .{ .name = "requeue", .serializer = ser.bool },
        .{ .name = "array_job_id", .serializer = ser.numberFlatNoValue },
        .{ .name = "array_task_id", .serializer = ser.numberFlatNoValue },
        .{ .name = "array_max_tasks", .serializer = ser.numberFlatNoValue },
        .{ .name = "batch_flag", .new_name = "is_batch", .serializer = ser.bool },
        .{ .name = "boards_per_node", .serializer = ser.numberFlatNoValue },
        .{ .name = "state_desc", .new_name = "state_description" },
        .{ .name = "wait4switch", .new_name = "wait_for_switch" },
        .{ .name = "contiguous", .serializer = ser.bool },
        .{ .name = "core_spec", .new_name = "specialized_cores", .serializer = ser.numberFlatNoValue },
        .{ .name = "cores_per_socket", .serializer = ser.numberFlatNoValue },
        .{ .name = "cpu_freq_min", .serializer = ser.numberFlatNoValue },
        .{ .name = "cpu_freq_max", .serializer = ser.numberFlatNoValue },
        .{ .name = "cpu_freq_gov", .serializer = ser.numberFlatNoValue },
        .{ .name = "cpus_per_tres", .serializer = ser.dict },
        .{ .name = "exc_nodes", .new_name = "excluded_nodes" },
        .{ .name = "features", .serializer = ser.array },
        //.{ .name = "deadline", .serializer = ser.numberFlatNoValue },
        .{ .name = "het_job_id", .serializer = ser.numberFlatNoValue },
        .{ .name = "gres_detail_cnt", .serializer = ser.noop },
        .{ .name = "licenses", .serializer = ser.array },
        .{ .name = "licenses_allocated", .serializer = ser.array },
        // TODO: boolNoValue
        // .{ .name = "oom_kill_step", .serializer = ser.boolNoValue },
        .{ .name = "ntasks_per_core", .serializer = ser.number },
        .{ .name = "ntasks_per_tres", .serializer = ser.number },
        .{ .name = "ntasks_per_node", .serializer = ser.number },
        .{ .name = "ntasks_per_socket", .serializer = ser.number },
        .{ .name = "ntasks_per_board", .serializer = ser.number },
        .{ .name = "sockets_per_node", .serializer = ser.number },
        .{ .name = "sockets_per_board", .serializer = ser.numberNoValue},
        .{ .name = "gres_detail_str", .new_name = "gres_detail", .serializer = ser.noop }, // TODO
        .{ .name = "pn_min_cpus", .new_name = "min_cpus_per_node", .serializer = ser.numberNoValue },
        .{ .name = "max_cpus", .serializer = ser.numberNoValue },
        .{ .name = "time_min", .serializer = ser.numberNoValue },
        .{ .name = "user_name", .serializer = ser.jobUserName },
        .{ .name = "std_out", .serializer = ser.jobStdOut },
    },
    .extra_members = &.{
            .{ .name = "memory_total", .serializer = ser.jobMemoryTotal },
    },
};

pub const Partition: SlurmType = .{
    .typ = slurm.Partition,
    .options = &.{
        .{ .name = "node_inx", .serializer = ser.noop },
        .{ .name = "job_defaults_list", .serializer = ser.noop },
        .{ .name = "deny_accounts", .serializer = ser.array, },
        .{ .name = "job_defaults_str", .new_name = "job_defaults", },
        .{ .name = "suspend_timeout", .serializer = ser.number, },
        // TODO: Needs parsing
        .{ .name = "def_mem_per_cpu", .serializer = ser.number, },
        .{ .name = "max_cpus_per_node", .serializer = ser.number, },
        .{ .name = "max_cpus_per_socket", .serializer = ser.number, },
        .{ .name = "max_nodes", .serializer = ser.number, },
        .{ .name = "resume_timeout", .serializer = ser.number, },
        .{ .name = "over_time_limit", .serializer = ser.number, },
        .{ .name = "allow_accounts", .serializer = ser.array, },
        .{ .name = "allow_alloc_nodes", .serializer = ser.array, },
        .{ .name = "allow_groups", .serializer = ser.array, },
        .{ .name = "allow_qos", .serializer = ser.array, },
        .{ .name = "deny_qos", .serializer = ser.array, },
        .{ .name = "qos_char", .new_name = "assigned_qos" },
        .{ .name = "tres_fmt_str", .new_name = "configured_tres", .serializer = ser.dict },
        .{ .name = "billing_weights_str", .new_name = "tres_billing_weights", .serializer = ser.dict },
    },
};

pub const ReservationResponse: SlurmType = .{
    .typ = slurm.Reservation.LoadResponse,
    .serializer = ser.loadResponse,
};

pub const PartitionResponse: SlurmType = .{
    .typ = slurm.Partition.LoadResponse,
    .serializer = ser.loadResponse,
};

pub const NodeResponse: SlurmType = .{
    .typ = slurm.Node.LoadResponse,
    .serializer = ser.loadResponse,
};

pub const JobResponse: SlurmType = .{
    .typ = slurm.Job.LoadResponse,
    .serializer = ser.loadResponse,
};

pub const JobResources: SlurmType = .{
    .typ = slurm.Job.Resources,
    .serializer = ser.noop,
};
