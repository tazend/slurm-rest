const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const Handler = @import("main.zig").Handler;
const Dumper = @import("json/Dumper.zig");
const Parser = @import("json/Parser.zig");
const openapi = @import("openapi.zig");
const params_path = @import("openapi/parameters/path.zig");
const params_query = @import("query_params.zig");

pub const route_categories = &.{
    @import("routes/jobs.zig"),
    @import("routes/nodes.zig"),
    @import("routes/steps.zig"),
    @import("routes/partitions.zig"),
    @import("routes/reservations.zig"),
    @import("routes/controller.zig"),
    @import("routes/db/accounts.zig"),
    @import("routes/db/jobs.zig"),
    @import("routes/db/users.zig"),
    @import("routes/db/associations.zig"),
};

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

pub const SlurmRequirements = struct {
    db_conn: bool = false,
    qos: bool = false,
    tres: bool = false,
};

const Description = struct {
    name: []const u8,
    method: []const u8,

    pub fn init(name: [:0]const u8) Description {
        @setEvalBranchQuota(5000);
        var itr1 = std.mem.splitBackwardsScalar(u8, name, '.');
        var itr2 = std.mem.splitScalar(u8, itr1.first(), ' ');
        const method = itr2.first();
        var buf: [64]u8 = undefined;

        return .{
            .method = std.ascii.lowerString(&buf, method),
            .name = itr2.rest(),
        };
    }
};

pub fn addRoutes2(router: anytype) void {
    inline for (route_categories) |category| {
        inline for (category.routes) |route| {
            const desc: Description = comptime .init(@typeName(route));
            const method_action = @field(@TypeOf(router.*), desc.method);
            method_action(router, desc.name, handlerRoute(route), .{});
        }
    }
}

pub fn RouteData(comptime R: type) type {
    return struct {
        pub const Meta = R.Meta;

        parameters: struct {
            path: if (Meta.parameters.path) |p| p.api_type else void,
            query: if (Meta.parameters.query) |q| q.api_type else void,
        },
        body: if (Meta.requestBody) |b| b.api_type else void,
        req: *httpz.Request,
        res: *httpz.Response,
        arena: std.mem.Allocator,
        db_conn: if (Meta.requirements.db_conn) *slurm.db.Connection else void,
        tres: if (Meta.requirements.tres) *slurm.List(*slurm.db.TrackableResource) else void,
        qos: if (Meta.requirements.qos) *slurm.List(*slurm.db.QoS) else void,

        pub fn init(ctx: *RequestContext) !@This() {
            const db_conn = if (Meta.requirements.db_conn)
                try slurm.db.Connection.open()
            else {};

            const tres = if (Meta.requirements.tres)
                try slurm.db.tres.load(db_conn, .{})
            else {};

            const qos = if (Meta.requirements.qos)
                try slurm.db.qos.load(db_conn, .{})
            else {};

            return .{
                .parameters = .{
                    .path = if (Meta.parameters.path) |p| try p.init(ctx) else {},
                    .query = if (Meta.parameters.query) |q| try q.init(ctx) else {},
                },
                .body = if (Meta.requestBody) |b| try Parser.parse2(b, ctx.arena, ctx.req.body() orelse return error.EmptyBody),
                .req = ctx.req,
                .res = ctx.res,
                .arena = ctx.arena,
                .db_conn = db_conn,
                .tres = tres,
                .qos = qos,
            };
        }

        pub fn deinit(self: *@This()) void {
            if (Meta.requirements.tres) self.tres.deinit();
            if (Meta.requirements.qos) self.qos.deinit();
            if (Meta.requirements.db_conn) self.db_conn.close();
        }

        pub fn write(self: *@This(), d: R.Response.api_type) !void {
            _ = self;
            _ = d;
        }
    };
}

pub fn handlerRoute(comptime R: type) Action {
    const H = struct {
        fn handle(h: *Handler, req: *httpz.Request, res: *httpz.Response) anyerror!void {
            var ctx: RequestContext = .{
                .arena = res.arena,
                .res = res,
                .req = req,
                .handler = h,
            };
            const B = R.Meta.response.ref.api_type;

            var data = RouteData(R).init(&ctx) catch |err| {
                const r: B = .{
                    .@"error" = .{
                        .title = @errorName(err),
                        .detail = "TODO",
                    },
                };
                return try respond(r, res);
            };
            defer data.deinit();

            const ret: B = R.handle(&data) catch |err| blk: {
                break :blk .{
                    .@"error" = .{
                        .title = @errorName(err),
                        .detail = "TODO",
                    },
                };
            };
            return try respond(ret, res);
        }
    };
    return &H.handle;
}

pub const RouteMeta = struct {
    tags: []const []const u8,
    summary: []const u8,
    description: []const u8,
    operationId: []const u8,
    security: ?[]const []const u8 = null,
    response: Response,
    requestBody: ?openapi.SchemaComponent = null,
    parameters: Parameters = .{},
    requirements: SlurmRequirements = .{},

    pub const Response = struct {
        ref: openapi.SchemaComponent,
        description: []const u8,
    };

    pub const Parameters = struct {
        path: ?params_path.Parameters = null,
        query: ?params_query.QueryParameterComponent = null,
    };
};
