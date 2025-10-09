const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const read = @import("read.zig");
const array = std.ArrayList;
const stdout = std.fs.File.stdout;
const json = std.json;

pub fn stringify(out: *std.Io.Writer.Allocating, json_obj: *const json.Value, oneLine: bool) ![]u8 {
    const writer = &out.writer;

    if (oneLine) {
        _ = try std.json.Stringify.value(json_obj, .{ .whitespace = .minified }, writer);
    } else {
        _ = try std.json.Stringify.value(json_obj, .{ .whitespace = .indent_1 }, writer);
    }
    const json_str = out.written();
    return json_str;
}
