const std = @import("std");
const slurm = @import("slurm");
const openapi = @import("../../openapi.zig");
const Property = openapi.Property;
const SchemaComponent = openapi.SchemaComponent;
const models = @import("../../models.zig");

pub const ReservationCoreSpecArray: SchemaComponent = .array(ReservationCoreSpec, .reservation_core_specs);
pub const Reservations:      SchemaComponent = .array(Reservation, .load_response);
pub const ReservationResponse =  openapi.GenericResponse("Reservation", "Reservation information");

pub const ReservationUpdatable: SchemaComponent = .{
    .api_type = slurm.Reservation.Updatable,
    .ignored_fields = &.{
        "job_ptr",
    },
    .properties = UpdatableMembers ++ &[_]Property{
        .{
            .name = "duration",
            .description = "Duration of the Reservation",
            .serde = .object(.number),
        },
    },
};

pub const ReservationUpdatableArray: SchemaComponent = .{
    .api_type = []const slurm.Reservation.Updatable,
    .ignored_fields = &.{
        "job_ptr",
    },
    .properties = NameMember ++ UpdatableMembers ++ &[_]Property{
        .{
            .name = "duration",
            .description = "Duration of the Reservation",
            .serde = .object(.number),
        },
    },
    .serde = .array(.container),
};

pub const Reservation: SchemaComponent = .{
    .api_type = slurm.Reservation,
    .ignored_fields = &.{
        "node_inx", "core_spec_cnt",
    },
    .properties = NameMember ++ UpdatableMembers ++ &[_]Property{
        .{
            .api_name = "core_spec",
            .name = "specialized_cores",
            .description = "Cores Reserved for the System",
            .serde = .array(.reservation_core_specs),
            .ref = ReservationCoreSpecArray,
        },
    },
};


pub const ReservationCoreSpec: SchemaComponent = .{
    .api_type = slurm.Reservation.CoreSpec,
    .properties = &.{
        .{
            .name = "node_name",
            .description = "Name of the Node",
            .serde = .string(.native),
        },
        .{
            .name = "core_id",
            .description = "Core ID",
            .serde = .string(.native),
        },
    },
};

pub const ReservationsResponse: SchemaComponent = .{
    .child = Reservations,
    .api_type = models.ReservationsResponse,
    .properties = &[_]Property{
        .{
            .name = "last_update",
            .description = "Time of last update of this data",
            .serde = .integer(.timestamp),
        },
        .{
            .name = "reservations",
            .description = "List of Reservations",
            .ref = Reservations,
            .serde = .string(.print),
        },
    } ++ openapi.BaseResponseProperties,
};

const NameMember: []const Property = &.{
    .{
        .name = "name",
        .description = "Name of the Reservation",
        .serde = .string(.native),
    },
};

const UpdatableMembers: []const Property = &.{
    .{
        .name = "burst_buffer",
        .description = "Burst Buffer Information",
        .serde = .string(.native),
    },
    .{
        .name = "accounts",
        .description = "List of allowed Accounts",
        .serde = .array(.csv),
    },
    .{
        .name = "users",
        .description = "List of allowed Users",
        .serde = .array(.csv),
    },
    .{
        .name = "comment",
        .description = "Arbitrary comment",
        .serde = .string(.native),
    },
    .{
        .api_name = "core_cnt",
        .name = "cores",
        .description = "Number of Cores reserved",
        .serde = .integer(.native),
    },
    .{
        .name = "start_time",
        .description = "Time when the Reservation starts",
        .serde = .integer(.timestamp),
    },
    .{
        .api_name = "node_cnt",
        .name = "node_count",
        .description = "Total number of nodes reserved",
        .serde = .integer(.native),
    },
    .{
        .api_name = "node_list",
        .name = "nodes",
        .description = "Nodes reserved",
        .serde = .string(.native),
    },
    .{
        .api_name = "tres_str",
        .name = "tres",
        .description = "TRES reserved",
        .serde = .dict(.key_value, &.{ .string, .integer }),
    },
    .{
        .name = "partition",
        .description = "Name of the Partition",
        .serde = .string(.native),
    },
    .{
        .api_name = "allowed_parts",
        .name = "allowed_partitions",
        .description = "List of allowed Partitions",
        .serde = .array(.csv),
    },
    .{
        .name = "end_time",
        .description = "Time when the Reservation ends",
        .serde = .integer(.timestamp),
    },
    .{
        .name = "flags",
        .description = "List of Flags",
        .serde = .array(.bitflag),
    },
    .{
        .name = "licenses",
        .description = "Names of Licenses in this Reservation",
        .serde = .array(.csv),
    },
    .{
        .name = "groups",
        .description = "Names of Groups allowed",
        .serde = .array(.csv),
    },
    .{
        .name = "features",
        .description = "Names of Features",
        .serde = .string(.native),
    },
    .{
        .name = "qos",
        .description = "Quality of Service assigned",
        .serde = .string(.native),
    },
    .{
        .name = "purge_comp_time",
        .description = "Purge Completion Time",
        .serde = .integer(.native),
    },
    .{
        .name = "max_start_delay",
        .description = "Maximum start delay",
        .serde = .integer(.native),
    },
};
