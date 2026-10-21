const std = @import("std");
const route = @import("../route.zig");
const categories = route.route_categories;
const Stringify = std.json.Stringify;
const Allocator = std.mem.Allocator;
const node_routes = @import("../routes/nodes.zig");
const openapi = @import("../openapi.zig");

pub const SpecReal = struct {
    openapi: []const u8 = "3.1.0",
    info: struct {
        title: []const u8 = "Slurm REST API",
        version: []const u8 = "slurm-X",
        description: []const u8 = "API to access and control slurm",
    } = .{},
    servers: []const []const u8 = &.{},
};

pub const Content = struct {
    @"application/json": struct {
        schema: struct {
            @"$ref": []const u8,
        },
    },

    pub fn fromSchema(schema: openapi.SchemaComponent) Content {
        return .{
            .@"application/json" = .{
                .schema = .{
                    .@"$ref" = "#/components/schemas/" ++ comptime schema.getName2(),
                },
            },
        };
    }
};

const Spec = struct {
    json: Stringify,
    allocator: Allocator,

    pub fn init(allocator: Allocator, writer: *std.Io.Writer) Spec {
        return .{
            .allocator = allocator,
            .json = .{
                .options = .{ .whitespace = .indent_4 },
                .writer = writer,
            },
        };
    }

    pub fn processRouteMeta(self: *Spec, meta: route.RouteMeta) !void {
        var jw = &self.json;

        try jw.beginObject();
        try jw.objectField("tags");
        try jw.write(meta.tags);
        try jw.objectField("summary");
        try jw.write(meta.summary);
        try jw.objectField("description");
        try jw.write(meta.description);
        try jw.objectField("operationId");
        try jw.write(meta.operationId);

        if (meta.requestBody) |body| {
            try jw.objectField("requestBody");
            try jw.beginObject();
            try jw.objectField("description");
            try jw.write("desc");
            try jw.objectField("content");
            try jw.write(Content.fromSchema(body));
            try jw.endObject();
        }

        if (meta.parameters.path != null or meta.parameters.query != null) {
            try jw.objectField("parameters");
            try jw.beginArray();

            if (meta.parameters.path) |p| {
                inline for (p.parameters) |param| {
                    try self.processPathParams(param);
                }
            }
            if (meta.parameters.query) |q| {
                inline for (q.parameters) |param| {
                    try self.processQueryParams(param);
                }
            }
            try jw.endArray();
        }

        try jw.objectField("responses");
        try jw.beginObject();
        try jw.objectField("200");
        try jw.write(meta.response);
        try jw.endObject();

        try jw.endObject();
    }

    pub fn processPathParams(self: *Spec, param: openapi.PathParameterComponent.Parameter) !void {
        var jw = &self.json;

        try jw.beginObject();
        {
            try jw.objectField("in");
            try jw.write("path");
            try jw.objectField("name");
            try jw.write(param.name);
            try jw.objectField("description");
            try jw.write(param.description);
            try jw.objectField("required");
            try jw.write(param.required);
            try jw.objectField("style");
            try jw.write(param.style);
            try jw.objectField("explode");
            try jw.write(param.explode);

            try jw.objectField("schema");
            try jw.beginObject();
            {
                try jw.objectField("type");
                try jw.write(param.@"type");
            }
            try jw.endObject();
        }
        try jw.endObject();
    }

    pub fn processQueryParams(self: *Spec, param: openapi.QueryParameterComponent.Parameter) !void {
        var jw = &self.json;
        try jw.beginObject();
        {
            try jw.objectField("in");
            try jw.write("query");
            try jw.objectField("name");
            try jw.write(param.name);
            try jw.objectField("description");
            try jw.write(param.description);
            try jw.objectField("required");
            try jw.write(param.required);
            try jw.objectField("style");
            try jw.write(param.style);
            try jw.objectField("explode");
            try jw.write(param.explode);

            try jw.objectField("schema");
            try jw.beginObject();
            {
                // TODO: Figure out the proper json type
                try jw.objectField("type");
                try jw.write("string");
            }
            try jw.endObject();
        }
        try jw.endObject();
    }

    pub fn processPaths(self: *Spec) !void {
        try self.json.objectField("paths");
        try self.json.beginObject();

        var seen: std.StringHashMapUnmanaged(void) = .empty;
        defer seen.deinit(self.allocator);

        inline for (node_routes.routes, 1..) |r, i| {
            const desc: route.Description = comptime .init(@typeName(r));

            const result = try seen.getOrPut(self.allocator, desc.name);
            if (!result.found_existing) {
                if (i > 1) try self.json.endObject();
                try self.json.objectField(desc.name);
                try self.json.beginObject();
            }

            try self.json.objectField(desc.method);
            try self.processRouteMeta(r.Meta);

            if (i == node_routes.routes.len) try self.json.endObject();
        }
        try self.json.endObject();
    }


    pub fn processOneSchema(self: *Spec, comptime name: [:0]const u8, schema: openapi.SchemaComponent) !void {
        try self.json.objectField(name);
        try self.json.beginObject();

        try self.json.objectField("type");
        try self.json.write(schema.serde.json_type);

        try self.json.objectField("properties");
        try self.json.beginObject();
        inline for (schema.properties) |prop| {
            try self.json.objectField(prop.name);
            try self.json.beginObject();

            if (prop.ref) |ref| {
                try self.json.objectField("$ref");
                try self.json.write("#/components/schema/" ++ comptime ref.getName2());
            } else {
                try self.json.objectField("type");
                try self.json.write(prop.serde.json_type);
                try self.json.objectField("description");
                try self.json.write(prop.description);

                if (prop.serde.is_enum) {
                    if (prop.serde.json_type == .array) {
                        try self.json.objectField("items");
                        try self.json.beginObject();
                        try self.json.objectField("type");
                        try self.json.write(prop.serde.json_array_type);
                    }
                    try self.json.objectField("enum");
                    try self.json.beginArray();
                    const ItemType = @FieldType(schema.api_type, prop.api_name orelse prop.name);
                    inline for (std.meta.fields(ItemType)) |f| {
                        @setEvalBranchQuota(5000);
                        if (!std.mem.startsWith(u8, f.name, "_")) try self.json.write(f.name);
                    }
                    try self.json.endArray();

                    if (prop.serde.json_type == .array) try self.json.endObject();
                }
            }
            try self.json.endObject();
        }
        try self.json.endObject();

        try self.json.endObject();
    }

    pub fn processComponents(self: *Spec) !void {
        try self.json.objectField("components");
        try self.json.beginObject();
        try self.json.objectField("schemas");
        try self.json.beginObject();

        const decls = @typeInfo(openapi).@"struct".decls;
        inline for (decls) |decl| {
            const field = @field(openapi, decl.name);
            if (@TypeOf(field) == openapi.SchemaComponent) {
                try self.processOneSchema(decl.name, field);
            }
        }

        try self.json.endObject();
        try self.json.endObject();
    }
};

pub fn process(allocator: Allocator) ![]const u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    const writer = &aw.writer;

    var spec: Spec = .init(allocator, writer);
    const real: SpecReal = .{};

    try spec.json.beginObject();
    inline for (std.meta.fields(SpecReal)) |f| {
        try spec.json.objectField(f.name);
        try spec.json.write(@field(real, f.name));
    }
    try spec.processPaths();
    try spec.processComponents();
    try spec.json.endObject();

    return aw.toOwnedSlice();
}
