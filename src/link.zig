const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const read = @import("read.zig");
const array = std.ArrayList;
const stdout = std.fs.File.stdout;
const json = std.json;
const fmt = @import("fmt.zig");

pub fn linkHeaders(alloc: Allocator, heading: *const array([]const u8), data: *const array([]const u8)) !std.StringHashMap([]const u8) {
    var map = std.StringHashMap([]const u8).init(alloc);
    for (heading.items, 0..) |header, idx| {
        if (data.items.len <= idx) break;

        const value = data.items[idx];
        _ = try map.put(header, value);
    }
    return map;
}

pub fn mapToJson(alloc: Allocator, map: *const std.StringHashMap([]const u8)) !json.Value {
    var obj = std.json.ObjectMap.init(alloc);

    var iter = map.iterator();
    while (iter.next()) |val| {
        const json_val = fmt.parseDynamicValue(val.value_ptr.*);
        _ = try obj.put(val.key_ptr.*, json_val);
    }

    const json_obj = std.json.Value{ .object = obj };
    return json_obj;
}
