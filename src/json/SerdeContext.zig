const std = @import("std");
const slurm = @import("slurm");
const Stringify = std.json.Stringify;
const ser = @import("new_dump_methods.zig");
const openapi = @import("../openapi.zig");
const Dumper = @import("Dumper.zig");

pub const NewDumpFN = *const fn(dumper: *Dumper, value: anytype, ctx: Dumper.Context) anyerror!void;
const SerdeContext = @This();
const DumpFN = NewDumpFN;

pub const JSONType = enum {
    object,
    string,
    number,
    integer,
    boolean,
    array,
    null,
};

json_type: JSONType,
json_array_type: ?JSONType = null,
json_object_types: ?[]const JSONType = null,
sx: Serde,

// Serializer that should be invoked
pub const ObjectTypes = enum {
    container,
    native,
    node_state,
    number,
    number_zero_is_noval,
};

pub const Serde = union(enum) {
    object: ObjectTypes,
    string: StringTypes,
    dict: DictionaryTypes,
    integer: IntegerTypes,
    number: void,
    array: ArrayTypes,
    boolean: BoolTypes,
    @"null": void,
};

pub fn object(comptime T: ObjectTypes) SerdeContext {
    return .{
        .json_type = .object,
        .sx = .{ .object = T },
    };
}

pub const DictionaryTypes = enum {
    gres_count,
    key_value,
};

pub fn dict(comptime T: DictionaryTypes, comptime json_types: []const JSONType) SerdeContext {
    return .{
        .json_type = .object,
        .json_object_types = json_types,
        .sx = .{ .dict = T },
    };
}

pub const StringTypes = enum {
    native,
    print,
    job_stdout,
    job_stdin,
    job_stderr,
    user_name,
    reason_user,
    step_id,
    sluid,
    @"enum",
};

pub fn string(comptime T: StringTypes) SerdeContext {
    return .{
        .json_type = .string,
        .sx = .{ .string = T },
    };
}

pub const IntegerTypes = enum {
    method_number_flat,
    method_number,
    std,
    native,
    native_zero_is_noval,
    native_infinite_is_null,
    node_idle_cpus,
    timestamp,
    job_memory,
    job_memory_total,
};

pub fn integer(comptime T: IntegerTypes) SerdeContext {
    return .{
        .json_type = .integer,
        .sx = .{ .integer = T },
    };
}

pub fn native(comptime T: JSONType) SerdeContext {
    const dump: SerdeContext = switch (T) {
        .array => .array(.native),
        .object => .object(.native),
        .string => .string(),
        else => @compileLog("Unsupported native JSONType " ++ @typeName(T)),
    };
    return dump;
}

pub fn unsupported() SerdeContext {
    return .{
        .dump = ser.unsupported,
        .json_type = .object,
    };
}

// Serializer that should be invoked
pub const ArrayTypes = enum {
    list,
    load_response,
    assocs_short,
    integers,
    csv,
    native,
    container,
    bitflag,
    nested_bitflag,
    reservation_core_specs,
};

pub fn array(comptime T: ArrayTypes) SerdeContext {
    return .{
        .json_type = .array,
        .json_array_type = switch (T) {
            .integers => .integer,
            .csv => .string,
            else => null,
        },
        .sx = .{ .array = T },
    };
}

// Serializer that should be invoked
pub const BoolTypes = enum {
    int,
    native,
};

pub fn boolean(comptime T: BoolTypes) SerdeContext {
    return .{
        .json_type = .boolean,
        .sx = .{ .boolean = T },
    };
}

pub fn noop() SerdeContext {
    return .{
        .json_type = .null,
        .sx = .{ .null = {} },
    };
}
