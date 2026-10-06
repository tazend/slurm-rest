const std = @import("std");
pub const SerdeContext = @import("json/SerdeContext.zig");
const JSONType = SerdeContext.JSONType;
const slurm = @import("slurm");
const models = @import("models.zig");

/// A specific Member or "Property" of a Schema Component
pub const Property = struct {
    api_name: ?[:0]const u8 = null,
    name: [:0]const u8,
    description: []const u8,
    serde: SerdeContext = .noop(),
    ref: ?SchemaComponent = null,
    // Whether this component is being considered for dumping/parsing without
    // existing on the API Type itself.
    extra: bool = false,

    pub fn getRef(self: Property) SchemaComponent {
        return self.ref orelse @compileError("Missing Ref on Property " ++ self.name);
    }

    pub fn getRefChild(self: Property) SchemaComponent {
        const r = self.getRef();
        return r.getChild();
    }
};

/// A Top-Level Schema Component
/// For example, this can be a "Node" or a "Job"
pub const SchemaComponent = struct {
    api_type: type,
//    description: []const u8,
    serde: SerdeContext = .object(.container),
    properties: []const Property = &.{},
    ignored_fields: []const []const u8 = &.{},
    child: ?SchemaComponent = null,

    pub fn getChild(self: SchemaComponent) SchemaComponent {
        return self.child orelse @compileError("Missing 'child' on " ++ @typeName(@TypeOf(self.api_type)));
    }

    pub fn array(comptime T: SchemaComponent, comptime A: SerdeContext.ArrayTypes) SchemaComponent {
        return .{
            .api_type = switch (A) {
                .list => slurm.List(*T.api_type),
                .load_response => T.api_type.LoadResponse,
                .assocs_short => slurm.List(*slurm.db.Association),
                else => T.api_type,
            },
            .serde = .array(A),
            .child = T,
        };
    }
};

pub fn GenericResponse(comptime name: [:0]const u8, comptime what: []const u8) SchemaComponent {
    if (!@hasDecl(@This(), name)) {
        @compileError("There is no SchemaComponent available for: '" ++ name ++ "'");
    }

    const T = @field(@This(), name);

    const decls = @typeInfo(models).@"struct".decls;
    const Response = blk: {
        for (decls) |decl| {
            const field = @field(models, decl.name);
            const Info = @typeInfo(@TypeOf(field));
            if (Info == .type) {
                if (@typeInfo(field) == .@"struct") {
                    if (@hasDecl(field, "Schema") and @TypeOf(field.Schema) == SchemaComponent) {
                        if (field.Schema.api_type == T.api_type) {
                            break :blk field;
                        }
                    }
                }
            }

        }
        @compileError("No response implementation found for " ++ @typeName(T.api_type));
    };

    const name_lower = comptime blk: {
        var buf: [name.len:0]u8 = undefined;
        buf[name.len] = 0;
        _ = std.ascii.lowerString(buf[0..name.len], name);
        break :blk buf;
    };

    return .{
        .api_type = Response,
        .properties = [_]Property{
            .{
                .api_name = "data",
                .name = &name_lower,
                .description = what,
                .ref = T,
                .serde = .string(.print),
            },
        } ++ BaseResponseProperties,
        .serde = .object(.container),
        .child = T,
    };
}

pub const Error: SchemaComponent = .{
    .api_type = models.Error,
    .properties = &.{
        .{
            .name = "title",
            .description = "Name of the Error",
            .serde = .string(.native),
        },
        .{
            .name = "detail",
            .description = "Explanation of the Error that occured",
            .serde = .string(.native),
        },
    },
};

pub const NumberU64: SchemaComponent = .{
    .api_type = models.Number(u64),
    .properties = &.{
        .{
            .name = "value",
            .description = "Number value",
            .serde = .integer(.native),
        },
        .{
            .name = "infinite",
            .description = "Whether the number is infinite or not",
            .serde = .boolean(.native),
        },
    },
};

pub fn Number(comptime T: type) SchemaComponent {
    return .{
        .api_type = models.Number(T),
        .properties = &.{
            .{
                .name = "value",
                .description = "Number value",
                .serde = .integer(.native),
            },
            .{
                .name = "infinite",
                .description = "Whether the number is infinite or not",
                .serde = .boolean(.native),
            },
        },
    };
}

pub const SlurmVersion: SchemaComponent = .{
    .api_type = models.SlurmVersion,
    .properties = &.{
        .{
            .name = "major",
            .description = "Major Version of Slurm",
            .serde = .integer(.native),
        },
        .{
            .name = "major",
            .description = "Major Version of Slurm",
            .serde = .integer(.native),
        },
        .{
            .name = "major",
            .description = "Major Version of Slurm",
            .serde = .integer(.native),
        },
    },
};

pub const SlurmMeta: SchemaComponent = .{
    .api_type = models.SlurmMeta,
    .properties = &.{
        .{
            .name = "cluster",
            .description = "Name of the cluster",
            .serde = .string(.native),
        },
        .{
            .name = "release",
            .description = "Slurm Release string",
            .serde = .string(.native),
        },
        .{
            .name = "version",
            .description = "Major, Minor and Micro version of Slurm",
            .ref = SlurmVersion,
            .serde = .object(.native),
        },
    },
};

pub const Meta: SchemaComponent = .{
    .api_type = models.Meta,
    .properties = &.{
        .{
            .name = "slurm",
            .description = "Slurm specific Metadata",
            .ref = SlurmMeta,
            .serde = .object(.native),
        },
    },
};

pub const Coordinator: SchemaComponent = .{
    .api_type = slurm.db.Coordinator,
    .properties = &.{
        .{
            .name = "name",
            .description = "Name of the Coordinator",
            .serde = .string(.native),
        },
        .{
            .name = "direct",
            .description = "Whether the Coordinator is direct",
            .serde = .boolean(.int),
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

pub const WCKey: SchemaComponent = .{
    .api_type = slurm.db.WCKey,
    .properties = &.{
        .{
            .name = "accounting_list",
            .description = "Accounting Informations",
            .serde = .noop(),
        },
        .{
            .name = "cluster",
            .description = "Name of the Cluster",
            .serde = .string(.native),
        },
        .{
            .name = "flags",
            .description = "WCKey Flags",
            .serde = .integer(.native),
        },
        .{
            .name = "id",
            .description = "ID",
            .serde = .integer(.native),
        },
        .{
            .name = "is_def",
            .description = "Whether the WCKey is default",
            .serde = .boolean(.int),
        },
        .{
            .name = "name",
            .description = "Name of the WCKey",
            .serde = .string(.native),
        },
        .{
            .name = "uid",
            .description = "UID of the User this WCKey is assigned to",
            .serde = .integer(.native),
        },
        .{
            .name = "user",
            .description = "Name of the User this WCKey is assigned to",
            .serde = .string(.native),
        },
    },
};

pub const Coordinators:      SchemaComponent = .array(Coordinator, .list);
pub const WCKeys:            SchemaComponent = .array(WCKey, .list);
pub const Steps:             SchemaComponent = .array(Step, .load_response);

pub const CoordinatorsResponse = GenericResponse("Coordinators", "List of Database Coordinators");
pub const WCKeysResponse =       GenericResponse("WCKeys", "List of Database WCKeys");

pub const BaseResponseProperties: []const Property = &.{
    .{
        .name = "meta",
        .description = "Metadata",
        .ref = Meta,
        .serde = .object(.native),
    },
    .{
        .name = "error",
        .description = "Errors",
        .ref = Error,
        .serde = .object(.native),
    },
};

pub const BaseResponse: SchemaComponent = .{
    .api_type = models.BaseResponse,
    .properties = BaseResponseProperties,
};

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
    } ++ BaseResponseProperties,
};

pub const SpecificationResponse: SchemaComponent = .{
    .api_type = models.OpenAPISpecificationResponse,
    .properties = [_]Property{
        .{
            .name = "spec",
            .description = "OpenAPI Specification",
            .serde = .string(.print),
        },
    } ++ BaseResponseProperties,
};

pub const reservation = @import("openapi/schemas/reservation.zig");
pub const ReservationCoreSpec = reservation.ReservationCoreSpec;
pub const ReservationCoreSpecArray = reservation.ReservationCoreSpecArray;
pub const Reservations = reservation.Reservations;
pub const ReservationResponse = reservation.ReservationResponse;
pub const ReservationsResponse = reservation.ReservationsResponse;
pub const Reservation = reservation.Reservation;

const dbjob = @import("openapi/schemas/db/job.zig");
pub const DBJob = dbjob.DBJob;
pub const DBJobs = dbjob.DBJobs;
pub const DBJobsResponse = dbjob.DBJobsResponse;
pub const DBJobResponse = dbjob.DBJobResponse;

const dbstep = @import("openapi/schemas/db/step.zig");
pub const DBStep = dbstep.DBStep;
pub const DBSteps = dbstep.DBSteps;
pub const DBStepsResponse = dbstep.DBStepsResponse;

const qos = @import("openapi/schemas/qos.zig");
pub const QoS = qos.QoS;
pub const QoSArray = qos.QoSArray;
pub const QoSResponse = qos.Response;
pub const QoSSingleResponse = qos.SingleResponse;

pub const part = @import("openapi/schemas/partition.zig");
pub const Partition = part.Partition;
pub const Partitions = part.Array;
pub const PartitionsResponse = part.Response;
pub const PartitionResponse = part.SingleResponse;

pub const slurmctld = @import("openapi/schemas/slurmctld.zig");
pub const ControllerStatistics = slurmctld.ControllerStatistics;
pub const ControllerStatisticsResponse = slurmctld.ControllerStatisticsResponse;

const node = @import("openapi/schemas/node.zig");
pub const Node = node.Node;
pub const Nodes = node.Nodes;
pub const NodesResponse = node.NodesResponse;
pub const NodeResponse = node.NodeResponse;
pub const NodeUpdatable = node.NodeUpdatable;

const job = @import("openapi/schemas/job.zig");
pub const Job = job.Job;
pub const Jobs = job.Jobs;
pub const JobsResponse = job.JobsResponse;
pub const JobResponse = job.JobResponse;
pub const JobScriptResponse = job.JobScriptResponse;

const account = @import("openapi/schemas/account.zig");
pub const Account = account.Account;
pub const Accounts = account.Accounts;
pub const AccountsResponse = account.Response;
pub const AccountResponse = account.SingleResponse;

const user = @import("openapi/schemas/db/user.zig");
pub const User = user.User;
pub const Users = user.Users;
pub const UsersResponse = user.UsersResponse;
pub const UserResponse = user.UserResponse;

const assoc = @import("openapi/schemas/association.zig");
pub const Association = assoc.Association;
pub const Associations = assoc.Associations;
pub const AssociationShort = assoc.AssociationShort;
pub const AssociationsShort = assoc.AssociationsShort;
pub const AssociationsResponse = assoc.AssociationsResponse;
