const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const read = @import("read.zig");
const array = std.ArrayList;
const stdout = std.fs.File.stdout;

const Vydia = struct {
    Currency: []const u8,
    USD: f32 = 0.0,
};

pub fn readFile(alloc: Allocator, file: *std.fs.File) ![]u8 {
    var result = try std.ArrayList(u8).initCapacity(alloc, 50);

    while (true) {
        const line = read.readLine(file) catch break;
        _ = try result.appendSlice(alloc, line);
    }
    return try result.toOwnedSlice(alloc);
}

pub fn decode() !void {
    const cwd = std.fs.cwd();
    var file = try cwd.openFile("alt.json", .{});
    defer file.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena.allocator();
    defer arena.deinit();
    const contents = try readFile(alloc, &file);
    defer alloc.free(contents);

    const val: std.json.Parsed([]Vydia) = try std.json.parseFromSlice([]Vydia, alloc, contents, .{ .ignore_unknown_fields = true });
    for (val.value) |entry| {
        print("{any}\n", .{entry});
    }
}
