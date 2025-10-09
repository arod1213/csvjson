const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const read = @import("read.zig");
const array = std.ArrayList;
const stdout = std.fs.File.stdout;
const json = std.json;

fn freeJsonValue(alloc: Allocator, val: *json.Value) void {
    switch (val.*) {
        .object => |*obj| {
            var iter = obj.iterator();
            while (iter.next()) |entry| {
                freeJsonValue(alloc, entry.value_ptr);
            }
            obj.deinit();
        },
        .array => |*arr| {
            for (arr.items) |*item| {
                freeJsonValue(alloc, item);
            }
            arr.deinit();
        },
        else => {},
    }
}
