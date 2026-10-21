const std = @import("std");
const mem = std.mem;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const openapi = @import("openapi.zig");
const SerdeContext = @import("json/SerdeContext.zig");

pub const AccountsResponse =          GenericResponse(openapi.components.account.Accounts);
pub const AssociationsResponse =      GenericResponse(openapi.components.assoc.Associations);
pub const AssociationResponse =       GenericResponse(openapi.components.assoc.Association);
pub const DBJobsResponse =            GenericResponse(openapi.components.dbjob.DBJobs);
pub const DBStepsResponse =           GenericResponse(openapi.components.dbstep.DBSteps);
pub const CoordinatorsResponse =      GenericResponse(openapi.components.coordinator.Coordinators);
pub const UsersResponse =             GenericResponse(openapi.components.user.Users);
pub const WCKeysResponse =            GenericResponse(openapi.components.wckey.WCKeys);
pub const WCKeyResponse =             GenericResponse(openapi.components.wckey.WCKey);
//pub const QueueResponse =             GenericResponse(openapi.Queue);
pub const JobResponse =               GenericResponse(openapi.components.job.Job);
pub const NodeResponse =              GenericResponse(openapi.components.node.Node);
pub const PartitionResponse =         GenericResponse(openapi.components.part.Partition);
pub const ReservationResponse =       GenericResponse(openapi.components.reservation.Reservation);
pub const DBJobResponse =             GenericResponse(openapi.components.dbjob.DBJob);
pub const UserResponse =              GenericResponse(openapi.components.user.User);
pub const QoSResponse =               GenericResponse(openapi.components.qos.QoSArray);
pub const QoSSingleResponse =         GenericResponse(openapi.components.qos.QoS);
pub const AccountSingleResponse =     GenericResponse(openapi.components.account.Account);

pub const ControllerStatisticsResponse = struct {
    statistics: ?[]const u8 = "{}",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const BaseResponse = struct {
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const StepsResponse = struct {
    last_update: std.c.time_t = 0,
    steps: ?[]const u8 = "[]",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const JobScriptResponse = struct {
    script: ?[]const u8 = "",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const OpenAPISpecificationResponse = struct {
    spec: ?[]const u8 = "",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const NodesResponse = struct {
    last_update: std.c.time_t = 0,
    nodes: ?[]const u8 = "[]",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const PartitionsResponse = struct {
    last_update: std.c.time_t = 0,
    partitions: ?[]const u8 = "[]",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const ReservationsResponse = struct {
    last_update: std.c.time_t = 0,
    reservations: ?[]const u8 = "[]",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const JobsResponse = struct {
    last_backfill: std.c.time_t = 0,
    last_update: std.c.time_t = 0,
    jobs: ?[]const u8 = "[]",
    @"error": ?Error = null,
    meta: ?Meta = null,
};

pub const APIError = error{} || slurm.err.Error;

pub const Error = struct {
    title: [:0]const u8,
    detail: []const u8,
};

pub const AssociationShort = struct {
    account: ?slurm.CStr = null,
    cluster: ?slurm.CStr = null,
    partition: ?slurm.CStr = null,
    user: ?slurm.CStr = null,
    id: u32 = 0,
};

pub const QueueSummary = struct {
    id: u32,
    state: ?[]const u8 = null,
    user_name: ?[]const u8 = null,
    account: ?[:0]const u8 = null,
    partition: ?[:0]const u8 = null,
    qos: ?[:0]const u8 = null,
    resources: ?Resources = null,

    const Resources = struct {
        cpus: u32,
        memory: u64,
        gpus: u32,
    };
};

pub const SlurmVersion = struct {
    major: u32,
    minor: u32,
    micro: u32,
};

pub const SlurmMeta = struct {
    cluster: ?[]const u8 = null,
    release: ?[]const u8 = null,
    version: SlurmVersion,
};

pub const Meta = struct {
    slurm: ?SlurmMeta = null,
};

pub fn GenericResponse(comptime S: openapi.SchemaComponent) type {
    return struct {
        @"error": ?Error = null,
        meta: ?Meta = null,
        data: ?[]const u8 = DefaultValue,

        pub const Schema: openapi.SchemaComponent = S;
        pub const DefaultValue: ?[]const u8 = switch(S.serde.json_type) {
            .array => "[]",
            .string => "",
            .object => "{}",
            else => @compileError("Unsupported response Type " ++ @tagName(S.serde.json_type)),
        };

        pub fn jsonStringify(self: *const @This(), jw: anytype) !void {
            try jw.beginObject();
            try jw.objectField("error");
            try jw.write(self.@"error");
            try jw.objectField("meta");
            try jw.write(self.meta);
            try jw.objectField("data");
            const data = if (self.data) |d|
                // If for some reason our data is valid but empty, write the
                // DefaultValue instead.
                if (d.len == 0) DefaultValue else d
            else
                null;
            std.debug.print("ds\n", .{});
            try jw.print("{?s}", .{data});
            try jw.endObject();
        }
    };
}

pub fn IDPathParameter(comptime T: type) type {
    return struct {
        id: T,
    };
}

pub const NamePathParameter = struct {
    name: [:0]const u8,
};

pub const JobIDPathParameter = IDPathParameter(u32);

pub fn Number(comptime T: type) type {
    return struct {
        value: ?T = null,
        infinite: ?bool = null,
    };
}
