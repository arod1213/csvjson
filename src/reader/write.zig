const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const stdout = std.fs.File.stdout;
const json = std.json;

pub fn stringify(writer: *std.Io.Writer, json_obj: *const json.Value, oneLine: bool) !void {
    if (oneLine) {
        _ = try std.json.Stringify.value(json_obj, .{ .whitespace = .minified }, writer);
    } else {
        _ = try std.json.Stringify.value(json_obj, .{ .whitespace = .indent_1 }, writer);
    }
}
