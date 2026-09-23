const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;
const models = @import("../../models.zig");

pub const Nodes:             SchemaComponent = .array(Node, .load_response);
pub const NodeResponse =         openapi.GenericResponse("Node", "Node information");

pub const NodesResponse: SchemaComponent = .{
    .child = Nodes,
    .api_type = models.NodesResponse,
    .properties = [_]Property{
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
    } ++ openapi.BaseResponseProperties,
};

pub const NodeUpdatable: SchemaComponent = .{
    .api_type = slurm.Node.Updatable,
    .properties = SharedMembers ++ &[_]Property{
        .{
            .name = "cert_token",
            .description = "Cert Token",
            .serde = .string(.native),
        },
        .{
            .name = "instance_id",
            .description = "List of Instance Ids",
            .serde = .array(.csv),
        },
        .{
            .name = "instance_type",
            .description = "List of Instance Types",
            .serde = .array(.csv),
        },
        .{
            .name = "address",
            .description = "List of Node addresses",
            .serde = .array(.csv),
        },
        .{
            .name = "hostname",
            .description = "List of Node Hostnames",
            .serde = .array(.csv),
        },
        .{
            .name = "names",
            .description = "List of Node Names to update",
            .serde = .array(.csv),
        },
        .{
            .name = "resume_after",
            .description = "Resume after this amount of seconds",
            .serde = .integer(.native),
        },
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

pub const Node: SchemaComponent = .{
    .api_type = slurm.Node,
    .properties = SharedMembers ++ &[_]Property{
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
//      .{
//          .name = "cpu_bind",
//          .description = "Default CPU Binding",
//          .serde = .array(.native),
//      },
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
            .ref = AccountingGatherEnergy,
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
            .ref = NodeState,
            .serde = .object(.container),
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
            .name = "reason_time",
            .description = "Timestamp when the Reason was set",
            .serde = .integer(.timestamp),
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
            .api_name = "utilization",
            .name = "idle_cpus",
            .description = "Idle CPUs of the Node",
            .serde = .integer(.node_idle_cpus),
            .extra = true,
        },
        .{
            .api_name = "reason_uid",
            .name = "reason_user",
            .description = "Name of the User who set the Reason",
            .serde = .string(.reason_user),
            .extra = true,
        },
    },
};

pub const NodeState: SchemaComponent = .{
    .api_type = slurm.Node.State,
    .properties = &.{
        .{
            .name = "base",
            .description = "The base state",
            .serde = .string(.@"enum"),
        },
        .{
            .name = "flags",
            .description = "The state flags",
            .serde = .array(.nested_bitflag),
        },
    },
    .serde = .object(.container),
};

const SharedMembers: []const Property = &.{
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
        .name = "extra",
        .description = "Arbitrary string attached to the Node",
        .serde = .string(.native),
    },
    .{
        .api_name = "features",
        .name = "features_configured",
        .description = "List of available features",
        .serde = .array(.csv),
    },
    .{
        .api_name = "features_act",
        .name = "features_active",
        .description = "List of active features",
        .serde = .array(.csv),
    },
    .{
        .name = "gres",
        .description = "List of GRES configured",
        .serde = .dict(.key_value, &.{ .string }),
        //.serde = .dict(.gres_count, &.{ .integer }),
    },
    .{
        .name = "state",
        .description = "State of the Node",
        .ref = NodeState,
        .serde = .object(.container),
    },
    .{
        .name = "reason",
        .description = "Reason for the Node being down or drained",
        .serde = .string(.native),
    },
    .{
        .name = "reason_uid",
        .description = "UID of the User that set the Reason",
        .serde = .integer(.native),
    },
    .{
        .name = "weight",
        .description = "Node weight",
        .serde = .integer(.native),
    },
};
