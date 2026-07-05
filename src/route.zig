const std = @import("std");
const slurm = @import("slurm");
const httpz = @import("httpz");
const Handler = @import("main.zig").Handler;

pub const RequestContext = struct {
    req: *httpz.Request,
    res: *httpz.Response,
    arena: std.mem.Allocator,
    handler: *Handler,
};

pub const Action = *const fn (*Handler, *httpz.Request, *httpz.Response) anyerror!void;

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
                        .name = @errorName(err),
                        .description = "TODO",
                    },
                };
            };
            try res.json(ret, .{});
        }
    };

    return &H.handle;
}
