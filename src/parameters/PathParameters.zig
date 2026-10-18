const std = @import("std");
const openapi = @import("../openapi.zig");
const models = openapi.models;
const RequestContext = @import("../route.zig").RequestContext;

pub fn parse(comptime P: openapi.PathParameterComponent, ctx: *RequestContext) !P.api_type {
    var out: P.api_type = undefined;
    inline for (P.parameters) |param| {
        const p = ctx.req.param(param.name) orelse return error.InvalidPathParameter;
        const T = @TypeOf(@field(out, param.name));

        @field(out, param.name) = switch (param.@"type") {
            .integer => try std.fmt.parseInt(T, p, 10),
            .string => try ctx.arena.dupeZ(u8, p),
            else => @compileError("Parsing Path NamePathParameters not supported for type " ++ param.@"type"),
        };
    }
    return out;
}
