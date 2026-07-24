const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const Handler = @import("main.zig").Handler;
const Dumper = @import("json/Dumper.zig");
const openapi = @import("openapi.zig");

pub const RequestContext = struct {
    req: *httpz.Request,
    res: *httpz.Response,
    arena: std.mem.Allocator,
    handler: *Handler,
};

pub const Action = *const fn (*Handler, *httpz.Request, *httpz.Response) anyerror!void;

pub fn respond(value: anytype, res: *httpz.Response) !void {
    var dumper: Dumper = .init(res.arena, &res.buffer.writer);
    try Dumper.writeRequireSchema(&dumper, value);
}

pub fn handler(comptime action: anytype) Action {
    const H = struct {
        fn handle(h: *Handler, req: *httpz.Request, res: *httpz.Response) anyerror!void {
            var ctx: RequestContext = .{
                .arena = res.arena,
                .res = res,
                .req = req,
                .handler = h,
            };

            const T = @typeInfo(@TypeOf(action)).@"fn".return_type.?;
            const B = @typeInfo(T).error_union.payload;
            const ret: B = action(&ctx) catch |err| blk: {
                break :blk .{
                    .@"error" = .{
                        .title = @errorName(err),
                        .detail = "TODO",
                    },
                };
            };
            try respond(ret, res);
//            try res.json(ret, .{});
        }
    };

    return &H.handle;
}

const Description = struct {
    name: []const u8,
    method: []const u8,
};

pub fn addRoutes(router: anytype, comptime api: type) void {
    inline for (@typeInfo(api).@"struct".decls) |decl| {
        const d: Description = comptime blk: {
            var itr = std.mem.splitScalar(u8, decl.name, ' ');
            const method = itr.first();
            var buf: [64]u8 = undefined;
            const method_lower = std.ascii.lowerString(&buf, method);
            const name = itr.rest();

            break :blk .{ .name = name, .method = method_lower};
        };
        const f = @field(api, decl.name);
        const method_action = @field(@TypeOf(router.*), d.method);
        method_action(router, d.name, handler(f), .{});
    }
}

pub const Route = struct {
    method: []const u8,
    path: []const u8,
    tags: []const []const u8,
    summary: []const u8,
    description: []const u8,
    operationId: []const u8,
    security: ?[]const []const u8 = null,
    responses: []const Responses,
    requestBody: ?openapi.SchemaComponent = null,
    parameters: Parameters = .{},

    pub const Responses = struct {
        code: u16 = 200,
        ref: openapi.SchemaComponent,
        description: []const u8,
    };

    pub const Parameters = struct {
        path: ?type = null,
        query: ?type = null,
    };
};
