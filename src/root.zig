//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const json = std.json;

// my modules
pub const fmt = @import("fmt.zig");
pub const write = @import("write.zig");
pub const link = @import("link.zig");
pub const read = @import("read.zig");
pub const cli = @import("cli.zig");

pub const CSVReader = struct {
    alloc: Allocator,
    file: *std.fs.File,
    headers: std.ArrayList([]const u8),
    done: bool = false,
    line_count: usize = 0,
    args: *const cli.Args(),
    separator: u8,

    pub fn init(alloc: Allocator, file: *std.fs.File, args: *const cli.Args()) !@This() {
        const sep = args.separator;

        const heading = try read.readUntilDelimiters(file, "\n");
        const headers = try collectFields(alloc, heading.?, sep);

        return .{
            .alloc = alloc,
            .file = file,
            .headers = headers,
            .args = args,
            .separator = sep,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.headers.deinit(self.alloc);
    }

    pub fn next(self: *@This(), out: *std.Io.Writer.Allocating) ![]const u8 {
        self.line_count += 1;
        out.clearRetainingCapacity();

        while (self.line_count <= self.args.offset) {
            const skipped = try read.readUntilDelimiters(self.file, "\n");
            if (skipped == null) return error.EOF;
            self.line_count += 1;
        }

        const line = try read.readUntilDelimiters(self.file, "\n");
        if (line == null) return error.EOF;

        const json_obj = try collectJSON(self.alloc, line.?, self.separator, &self.headers);

        const json_str = try write.stringify(out, &json_obj, self.args.minified);
        return json_str;
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

fn collectJSON(alloc: Allocator, line: []const u8, sep: u8, headers: *array([]const u8)) !json.Value {
    var data = try collectFields(alloc, line, sep);
    defer data.deinit(alloc);
    var map = try link.linkHeaders(alloc, headers, &data);
    defer map.deinit();

    const json_obj = try link.mapToJson(alloc, &map);
    return json_obj;
}
