const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;

pub fn readLine(file: *std.fs.File) ![]u8 {
    const alloc = std.heap.page_allocator;
    var list = try std.ArrayList(u8).initCapacity(alloc, 1);
    errdefer list.deinit(alloc);

    while (true) {
        var b: [1]u8 = undefined;

        const n = try file.read(&b);
        if (n == 0) {
            if (list.items.len == 0) return error.EOF;
            break;
        }

        if (b[0] == '\n') break;
        try list.append(alloc, b[0]);
    }
    return try list.toOwnedSlice(alloc);
}

// reads until delims or EOF
pub fn readUntilDelimiters(file: *std.fs.File, delimiters: []const u8) !?[]u8 {
    const alloc = std.heap.page_allocator;
    var list = try std.ArrayList(u8).initCapacity(alloc, 1);
    defer list.deinit(alloc);

    blk: while (true) {
        var b: [1]u8 = undefined;

        const n = try file.read(&b);
        if (n == 0) {
            if (list.items.len == 0) return null; // EOF
            break :blk;
        }

        for (delimiters) |c| {
            if (b[0] == c) break :blk;
        }

        try list.append(alloc, b[0]);
    }
    return try list.toOwnedSlice(alloc);
}

// reads until substring found or EOF
pub fn readUntil(file: *std.fs.File, comptime needle: []const u8) !?[]u8 {
    assert(needle.len > 0);

    const alloc = std.heap.page_allocator;
    var list = try std.ArrayList(u8).initCapacity(alloc, 1);
    defer list.deinit(alloc);

    while (true) {
        var b: [1]u8 = undefined;

        const n = try file.read(&b);
        if (n == 0) {
            if (list.items.len == 0) return null; // EOF
            return error.NotFound;
        }

        if (list.items.len >= needle.len) {
            assert(list.items.len > 0);
            assert(list.items.len >= needle.len);

            const lo = list.items.len - needle.len;
            assert(lo >= 0);

            const slice = list.items[lo..];
            if (std.mem.eql(u8, slice, needle)) {
                break;
            }
        }

        try list.append(alloc, b[0]);
    }

    // remove substring
    assert(list.items.len >= needle.len);
    for (0..needle.len) |_| {
        _ = list.pop();
    }

    return try list.toOwnedSlice(alloc);
}
