const std = @import("std");
const mem = std.mem;
const Stringify = std.json.Stringify;
const slurm = @import("slurm");
const json = @import("json.zig");
const openapi = @import("openapi.zig");
const SerdeContext = @import("json/SerdeContext.zig");

pub const AccountsResponse =          GenericResponse(openapi.Accounts);
pub const AssociationsResponse =      GenericResponse(openapi.Associations);
pub const DBJobsResponse =            GenericResponse(openapi.DBJobs);
pub const DBStepsResponse =           GenericResponse(openapi.DBSteps);
pub const CoordinatorsResponse =      GenericResponse(openapi.Coordinators);
pub const UsersResponse =             GenericResponse(openapi.Users);
pub const WCKeysResponse =            GenericResponse(openapi.WCKeys);
//pub const QueueResponse =             GenericResponse(openapi.Queue);
pub const JobResponse =               GenericResponse(openapi.Job);
pub const NodeResponse =              GenericResponse(openapi.Node);
pub const PartitionResponse =         GenericResponse(openapi.Partition);
pub const ReservationResponse =       GenericResponse(openapi.Reservation);
pub const DBJobResponse =             GenericResponse(openapi.DBJob);
pub const QoSResponse =               GenericResponse(openapi.QoSArray);

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
    account: ?slurm.CStr,
    cluster: ?slurm.CStr,
    partition: ?slurm.CStr,
    user: ?slurm.CStr,
    id: u32,
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
            .null => null,
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
