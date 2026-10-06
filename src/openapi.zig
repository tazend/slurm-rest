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

const step = @import("openapi/schemas/step.zig");
pub const Step = step.Step;
pub const Steps = step.Steps;
pub const StepsResponse = step.StepsResponse;
pub const StepID = step.StepID;

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

const coordinator = @import("openapi/schemas/db/coordinator.zig");
pub const Coordinator = coordinator.Coordinator;
pub const Coordinators = coordinator.Coordinators;
pub const CoordinatorsResponse = coordinator.CoordinatorsResponse;

const wckey = @import("openapi/schemas/db/wckey.zig");
pub const WCKey = wckey.WCKey;
pub const WCKeys = wckey.WCKeys;
pub const WCKeysResponse = wckey.WCKeysResponse;

const assoc = @import("openapi/schemas/association.zig");
pub const Association = assoc.Association;
pub const Associations = assoc.Associations;
pub const AssociationShort = assoc.AssociationShort;
pub const AssociationsShort = assoc.AssociationsShort;
pub const AssociationsResponse = assoc.AssociationsResponse;
