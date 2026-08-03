const std = @import("std");
const httpz = @import("httpz");
const slurm = @import("slurm");
const openapi = @import("../openapi.zig");
const models = @import("../models.zig");
const RequestContext = @import("../route.zig").RequestContext;
const RouteMeta = @import("../route.zig").RouteMeta;
const RouteData = @import("../route.zig").RouteData;
const SlurmRequirements = @import("../route.zig").SlurmRequirements;
const dump = @import("../json/Dumper.zig").dump;

const path_params = @import("../openapi/parameters/path.zig");

pub const routes = &.{
    @"GET /reservations",
    @"GET /reservations/:name",
    @"DELETE /reservations/:name",
};

pub const @"GET /reservations" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Reservations",
        },
        .summary = "Get Reservations",
        .description = "Get all Reservations in the system",
        .operationId = "getReservations",
        .response = .{
            .ref = openapi.ReservationsResponse,
            .description = "TODO",
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.ReservationsResponse {
        const resp = try slurm.reservation.load();
        defer resp.deinit();
        return .{
            .reservations = try dump(ctx.arena, resp),
            .last_update = resp.last_update,
        };
    }
};

pub const @"GET /reservations/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Reservations",
        },
        .summary = "Get Reservation",
        .description = "Get one specific Reservation",
        .operationId = "getReservation",
        .response = .{
            .ref = openapi.ReservationResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.Reservation,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.ReservationResponse {
        const resp = try slurm.reservation.load();
        defer resp.deinit();
        const resv = resp.find(ctx.parameters.path.name) orelse return slurm.Error.ReservationInvalid;
        return .{ .data = try dump(ctx.arena, resv) };
    }
};

pub const @"DELETE /reservations/:name" = struct {
    pub const Meta: RouteMeta = .{
        .tags = &.{
            "Reservations",
        },
        .summary = "Delete Reservation",
        .description = "Delete one specific Reservation",
        .operationId = "deleteReservation",
        .response = .{
            .ref = openapi.BaseResponse,
            .description = "TODO",
        },
        .parameters = .{
            .path = path_params.Reservation,
        },
    };

    pub fn handle(ctx: *const RouteData(@This())) !models.BaseResponse {
        try slurm.reservation.deleteByName(ctx.parameters.path.name);
        return .{};
    }
};
