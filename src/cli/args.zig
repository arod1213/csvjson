const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const expect = std.testing.expect;

const Allocator = std.mem.Allocator;
const HashMap = std.StringHashMap;
const ArrayList = std.ArrayList;

pub fn parseField(alloc: Allocator, comptime T: type, args: *const HashMap(ArrayList([]const u8)), key: []const u8) !ArrayList(T) {
    var list = try ArrayList(T).initCapacity(alloc, 3);
    if (args.get(key)) |vals| {
        for (vals.items) |item| {
            if (makeType(T, item)) |x| {
                try list.append(alloc, x);
            } else {
                return error.ParseError;
            }
        }
    }
    return list;
}

pub fn argsToMap(alloc: Allocator) !HashMap(ArrayList([]const u8)) {
    const args = std.os.argv;
    var map = HashMap(ArrayList([]const u8)).init(alloc);

    var last_key: ?[]const u8 = null;
    for (args) |arg| {
        const text: []const u8 = std.mem.span(arg);
        if (std.mem.startsWith(u8, text, "-")) {
            last_key = text;
            _ = try map.put(text, undefined);
            continue;
        }
        if (last_key) |key| {
            var entry = try map.getOrPut(key);
            if (!entry.found_existing) {
                entry.value_ptr.* = try ArrayList([]const u8).initCapacity(alloc, 3);
            }
            try entry.value_ptr.append(alloc, text);
        }
    }
    return map;
}

pub const ParseError = error{ InvalidBool, InvalidEnum };
fn makeType(comptime T: type, val: []const u8) ?T {
    const info = @typeInfo(T);
    return switch (info) {
        .pointer => |p| if (p.size == .slice and p.child == u8)
            return val
        else
            unreachable,

        .int => std.fmt.parseInt(T, val, 10) catch null,
        .float => std.fmt.parseFloat(T, val) catch null,
        .enum_literal, .@"enum" => std.meta.stringToEnum(T, val),
        .bool => if (std.mem.eql(u8, val, "true")) true else if (std.mem.eql(u8, val, "false")) false else null,
        else => unreachable,
    };
}

test "make type" {
    {
        const a = "56";
        const b: usize = 56;
        try expect(makeType(usize, a) == b);
    }
    {
        const x = enum { other, thing };
        const a = "other";
        const b = .other;
        try expect(makeType(x, a) == b);
    }
    {
        const a = "5.7";
        const b: f64 = 5.7;
        try expect(makeType(f64, a) == b);
    }
    {
        const a = "true";
        const b = true;
        try expect(makeType(bool, a) == b);
    }
    {
        const a = "false";
        const b = false;
        try expect(makeType(bool, a) == b);
    }
    {
        const a = "fsle";
        const answer = makeType(bool, a);
        try expect(answer == null);
    }
}
