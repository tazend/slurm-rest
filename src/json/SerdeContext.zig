const std = @import("std");
const slurm = @import("slurm");
const Stringify = std.json.Stringify;
const ser = @import("new_dump_methods.zig");
const openapi = @import("../openapi.zig");
const Dumper = @import("Dumper.zig");
const Parser = @import("Parser.zig");

const SerdeContext = @This();
const DumpFN = Dumper.NewDumpFN;
const ParseFN = Parser.ParseFN;

//pub const DumpFN = *const fn(*Stringify, anytype, anytype, anytype) anyerror!void;
//pub const ParseFN = *const fn(*Stringify, anytype, anytype, anytype) anyerror!void;

pub const JSONType = enum {
    object,
    string,
    number,
    integer,
    boolean,
    array,
    null,
};

dump: DumpFN,
parse: ParseFN,
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

pub const Serde = union {
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
        .dump = switch (T) {
            .container => ser.container,
            .native => ser.native,
            .node_state => ser.nodeState,
            .number => ser.number,
            .number_zero_is_noval => ser.numberNoValue,
        },
        .parse = switch (T) {
            .container => Parser.container,
            .native => Parser.native,
            .node_state => Parser.container,
            .number => Parser.number,
            .number_zero_is_noval => Parser.unsupported,
        },
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
        .dump = switch (T) {
            .gres_count => ser.gresDict,
            .key_value => ser.dict,
        },
        .parse = switch (T) {
            .key_value => Parser.dict,
            else => Parser.noop,
        },
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
    step_id,
    sluid,
    node_state_base,
    @"enum",
};

pub fn string(comptime T: StringTypes) SerdeContext {
    return .{
        .dump = switch (T) {
            .native, .@"enum" => ser.native,
            .print => ser.printString,
            .job_stdout => ser.stdio("std_out"),
            .job_stdin => ser.stdio("std_in"),
            .job_stderr => ser.stdio("std_err"),
            .user_name => ser.userName("user_id"),
            .step_id => ser.stepIDString,
            .sluid => ser.sluid,
            .node_state_base => ser.nodeStateBase,
        },
        .parse = switch (T) {
            .@"enum" => Parser.@"enum",
            inline else => Parser.string,
        },
        .json_type = .string,
        .sx = .{ .string = T },
    };
}

pub const IntegerTypes = enum {
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
        .dump = switch (T) {
            .std => ser.native,
            .native => ser.numberFlat,
            .native_zero_is_noval => ser.numberFlatNoValue,
            .native_infinite_is_null => ser.numberFlatNoInfinite,
            .node_idle_cpus => ser.nodeIdleCpus,
            .timestamp => ser.timestampRaw,
            .job_memory => ser.jobMemory,
            .job_memory_total => ser.jobMemoryTotal,
        },
        .parse = switch (T) {
            .native, .native_zero_is_noval => Parser.integer,
            inline else => Parser.unsupported,
        },
        .json_type = .integer,
        .sx = .{ .integer = T },
    };
}

pub fn native(comptime T: JSONType) SerdeContext {
    var dump: SerdeContext = switch (T) {
        .array => .array(.native),
        .object => .object(.native),
        .string => .string(),
        else => @compileLog("Unsupported native JSONType " ++ @typeName(T)),
    };
    dump.parse = Parser.unsupported;
    return dump;
}

pub fn unsupported() SerdeContext {
    return .{
        .dump = ser.unsupported,
        .parse = Parser.unsupported,
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
    bitflag,
    nested_bitflag,
};

pub fn array(comptime T: ArrayTypes) SerdeContext {
    return .{
        .dump = switch (T) {
            .list => ser.list,
            .load_response => ser.loadResponse,
            .assocs_short => ser.assocsShort,
            .integers => ser.arrayInt,
            .csv => ser.array,
            .native, .bitflag => ser.native,
            .nested_bitflag => ser.nestedBitflag,
        },
        .parse = switch (T) {
            .csv => Parser.array,
            .native => Parser.native,
            .bitflag, .nested_bitflag => Parser.arrayBitflag,
            .list => Parser.arrayContainerToList,
            .assocs_short => Parser.assocsShort,
            else => Parser.noop,
        },
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
        .dump = switch (T) {
            .int => ser.bool,
            .native => ser.native,
        },
        .parse = Parser.noop,
        .json_type = .boolean,
        .sx = .{ .boolean = T },
    };
}

pub fn noop() SerdeContext {
    return .{
        .dump = ser.noop,
        .parse = Parser.noop,
        .json_type = .null,
        .sx = .{ .null = {} },
    };
}
