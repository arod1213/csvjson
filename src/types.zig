const std = @import("std");
const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const ArrayList = std.ArrayList;
const HashMap = std.HashMap;
const assert = std.debug.assert;
const expect = std.testing.expect;
const print = std.debug.print;

fn json_to_str(alloc: Allocator, value: *const Value) ![]const u8 {
    return switch (value.*) {
        .string => "String",
        .bool => "Bool",
        .float => "Float",
        .integer => "Int",
        .null => "Null",
        .number_string => "Num string",
        .array => |x| array_blk: {
            var new_list = try ArrayList([]const u8).initCapacity(alloc, 3);
            defer new_list.deinit(alloc);

            for (x.items) |inside| {
                const st = try json_to_str(alloc, &inside);
                try store_info(alloc, st, &new_list);
            }
            const slices = try new_list.toOwnedSlice(alloc);
            const flat = try std.mem.join(alloc, " | ", slices);

            const concat = try std.fmt.allocPrint(alloc, "{s}{s}", .{ "Array of ", flat });
            break :array_blk concat;
        },

        // this should be unreachable as the objects will be parsed already
        .object => "Obj",
    };
}

pub fn parse_types(alloc: Allocator, list: ArrayList(std.json.ObjectMap)) !*std.StringHashMap([]const u8) {
    var type_map = std.StringHashMap(*ArrayList([]const u8)).init(alloc);

    for (list.items) |item| {
        var iter = item.iterator();
        while (iter.next()) |pair| {
            const key = pair.key_ptr;
            const value = pair.value_ptr;

            var pair_info = type_map.get(key.*);
            _ = &pair_info;

            if (pair_info != null) {
                const ptr = pair_info.?;
                const json_str = try json_to_str(alloc, value);
                try store_info(alloc, json_str, ptr);
            } else {
                const ptr = try alloc.create(ArrayList([]const u8));
                ptr.* = try ArrayList([]const u8).initCapacity(alloc, 2);
                try type_map.put(key.*, ptr);
                const json_str = try json_to_str(alloc, value);
                try store_info(alloc, json_str, ptr);
            }
        }
    }

    var type_map_flat = std.StringHashMap([]const u8).init(alloc);
    var map_iter = type_map.iterator();
    while (map_iter.next()) |map_pair| {
        const key = map_pair.key_ptr;
        const value = map_pair.value_ptr.*;

        const slices = try value.toOwnedSlice(alloc);
        const flat = try std.mem.join(alloc, " | ", slices);
        try type_map_flat.put(key.*, flat);
    }
    return &type_map_flat;
}

pub fn inSlice(haystack: [][]const u8, needle: []const u8) bool {
    for (haystack) |thing| {
        if (std.mem.eql(u8, thing, needle)) {
            return true;
        }
    }
    return false;
}

fn store_info(alloc: Allocator, val: []const u8, existing: *ArrayList([]const u8)) !void {
    const exists = inSlice(existing.items, val);
    if (!exists) {
        try existing.append(alloc, val);
    }
}

test "store_info" {
    const alloc = std.testing.allocator;
    var list = try std.ArrayList(Value).initCapacity(alloc, 10);
    defer list.deinit(alloc);
    try list.appendSlice(alloc, &[_]Value{
        .{ .float = 10.0 },
        .{ .null = {} },
    });
    const text = try store_info(alloc, &list);
    try expect(std.mem.eql(u8, text, "FLOAT, NULL"));
}

fn get_types(alloc: Allocator, cache: std.HashMap([]const u8, std.ArrayList(Value))) !*const HashMap([]const u8, Value) {
    const map = try std.HashMap([]const u8, Value).init(alloc);
    var val_list = cache.iterator();
    while (val_list.next()) |vals| {
        const value = store_info(alloc, vals.value_ptr);
        map.put(vals.key_ptr, std.json.Value{ .str = value });
    }
    return &map;
}
