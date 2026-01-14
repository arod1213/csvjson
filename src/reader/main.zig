const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const json = std.json;

const log = std.log;

pub const fmt = @import("./fmt.zig");
pub const write = @import("./write.zig");
pub const link = @import("./link.zig");
pub const types = @import("./types.zig");
pub const args = @import("./args.zig");

pub const CSVReader = struct {
    alloc: Allocator,
    input: *const args.ReadArgs(),
    reader: *std.Io.Reader,
    headers: std.ArrayList([]const u8),

    separator: u8,
    line_count: usize = 0,
    done: bool = false,

    pub fn init(alloc: Allocator, reader: *std.Io.Reader, arg_list: *const args.ReadArgs()) !@This() {
        const sep = arg_list.separator;

        const raw = try reader.takeDelimiter('\n');
        if (raw == null) {
            return error.NoHeader;
        }
        const heading = std.mem.trimEnd(u8, raw.?, "\r");
        const headers = try collectFields(alloc, heading, sep);

        return .{
            .alloc = alloc,
            .reader = reader,
            .headers = headers,
            .input = arg_list,
            .separator = sep,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.headers.deinit(self.alloc);
    }

    pub fn next(self: *@This()) !std.json.ObjectMap {
        self.line_count += 1;

        while (self.line_count <= self.input.offset) {
            log.debug("skipping line\n", .{});
            _ = try self.reader.takeDelimiter('\n');
            self.line_count += 1;
        }

        const raw = try self.reader.takeDelimiter('\n');
        if (raw == null) {
            return error.NoHeader;
        }
        const line = std.mem.trimEnd(u8, raw.?, "\r");

        return try collectObject(self.alloc, line, self.separator, &self.headers);
    }
};

fn collectFields(alloc: Allocator, line: []const u8, sep: u8) !array([]const u8) {
    var arr = try array([]const u8).initCapacity(alloc, 10);

    var start: usize = 0;
    while (true) {
        const field = fmt.getField(alloc, line, sep, &start) catch break;
        _ = arr.append(alloc, field) catch break;
    }
    return arr;
}

test "collect fields" {
    const alloc = std.testing.allocator;
    const line = "giraffe,dog,cat,\"[alligator, crocodile]\"";
    const sep = ',';

    var arr = try std.ArrayList([]const u8).initCapacity(alloc, 4);
    defer arr.deinit(alloc);
    try arr.append(alloc, "giraffe");
    try arr.append(alloc, "dog");
    try arr.append(alloc, "cat");
    try arr.append(alloc, "[alligator, crocodile]");

    var answer = try collectFields(alloc, line, sep);
    defer answer.deinit(alloc);
    for (arr.items, 0..) |expected, i| {
        var result = answer.items[i];
        _ = &result;
        try expect(std.mem.eql(u8, expected, result));
        alloc.free(result);
    }
}

fn collectObject(alloc: Allocator, line: []const u8, sep: u8, headers: *array([]const u8)) !std.json.ObjectMap {
    var data = try collectFields(alloc, line, sep);
    defer data.deinit(alloc);

    var map = try link.linkHeaders(alloc, headers, &data);
    defer map.deinit();

    return try link.mapToObject([]const u8, alloc, &map);
}

test "mem" {
    const alloc = std.testing.allocator;
    const line = "giraffe,dog,cat,\"[alligator, crocodile]\"";
    const sep = ',';

    var arr = try std.ArrayList([]const u8).initCapacity(alloc, 4);
    defer arr.deinit(alloc);
    try arr.append(alloc, "row1");
    try arr.append(alloc, "row2");
    try arr.append(alloc, "row3");
    try arr.append(alloc, "row4");

    var obj = try collectObject(alloc, line, sep, &arr);
    defer obj.deinit();
}
