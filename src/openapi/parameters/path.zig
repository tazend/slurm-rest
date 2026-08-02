const std = @import("std");
const JSONType = @import("../../json/SerdeContext.zig").JSONType;
const models = @import("../../models.zig");
const RequestContext = @import("../../route.zig").RequestContext;

pub const Style = enum {
    simple,
    form,
};

pub const Parameter = struct {
    name: []const u8,
    description: []const u8,
    required: bool = true,
    style: Style = .simple,
    explode: bool = false,
    @"type": JSONType,
};

pub const Parameters = struct {
    api_type: type,
    parameters: []const Parameter,

    pub const init = parse;
};

pub fn NamePathParameter(comptime name: []const u8) Parameters {
    return .{
        .api_type = models.NamePathParameter,
        .parameters = &.{
            .{
                .name = "name",
                .description = "Name of the " ++ name,
                .type = .string,
            },
        },
    };
}

pub const JobIDPathParameter: Parameters = .{
    .api_type = models.JobIDPathParameter,
    .parameters = &.{
        .{
            .name = "id",
            .description = "ID of the Job to operate on",
            .type = .integer,
        },
    },
};

pub const Node = NamePathParameter("Node");
pub const Partition = NamePathParameter("Partition");
pub const Reservation = NamePathParameter("Reservation");
pub const AccountParameter = NamePathParameter("Account");

pub fn parse(comptime P: Parameters, ctx: *RequestContext) !P.api_type {
    var out: P.api_type = undefined;
    inline for (P.parameters) |param| {
        const p = ctx.req.param(param.name) orelse return error.InvalidPathParameter;
        const T = @TypeOf(@field(out, param.name));

        @field(out, param.name) = switch (param.@"type") {
            .integer => try std.fmt.parseInt(T, p, 10),
            .string => try ctx.arena.dupeZ(u8, p),
            else => @compileError("Parsing Path Parameters not supported for type " ++ param.@"type"),
        };
    }
    return out;
}
