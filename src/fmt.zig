const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const read = @import("read.zig");
const array = std.ArrayList;
const stdout = std.fs.File.stdout;
const json = std.json;

pub fn parseDynamicValue(s: []const u8) json.Value {
    if (std.mem.eql(u8, s, "null")) {
        return json.Value{ .null = {} };
    } else if (std.mem.eql(u8, s, "true")) {
        return json.Value{ .bool = true };
    } else if (std.mem.eql(u8, s, "false")) {
        return json.Value{ .bool = false };
    }

    if (std.fmt.parseInt(i64, s, 10)) |int_val| {
        return json.Value{ .integer = int_val };
    } else |_| {}

    if (std.fmt.parseFloat(f64, s)) |float_val| {
        return json.Value{ .float = float_val };
    } else |_| {}

    return json.Value{ .string = s };
}

pub fn getField(alloc: Allocator, line: []const u8, sep: u8, start_pos: *usize) ![]const u8 {
    if (line.len == 0) return error.Empty;
    if (start_pos.* >= line.len) return error.OutOfBounds;

    const slice = line[start_pos.*..];
    if (slice.len == 0) return error.Empty;

    const start_char = slice[0];
    const isNested = start_char == '\"';
    var isEscaped: bool = !isNested;

    var buf = try alloc.alloc(u8, slice.len);
    var idx: usize = 0;
    for (slice) |c| {
        if (c == sep and isEscaped) break;
        if (idx != 0 and c == '\"') {
            isEscaped = true;
        }
        buf[idx] = c;
        idx += 1;
    }

    start_pos.* += idx + 1; // + 1 to skip comma

    const result = cleanText(buf[0..idx]);
    idx = result.len;

    var i: usize = 0;
    while (i < result.len) : (i += 1) {
        buf[i] = result[i];
    }

    if (result.len != slice.len) {
        _ = alloc.resize(buf, idx);
    }
    return result;
}

fn cleanText(line: []const u8) []const u8 {
    var result = line;

    // strip quotes
    if (line.len > 1 and line[0] == '\"' and line[line.len - 1] == '\"') {
        result = line[1 .. line.len - 1];
    }

    result = std.mem.trim(u8, result, "\r\n");
    return result;
}

test "read until" {
    const alloc = std.testing.allocator;
    const line = "\"1, 2, 3, 4\",6";
    var start: usize = 0;
    {
        const res = try getField(alloc, line, &start);
        defer alloc.free(res);
        const answer = "\"1, 2, 3, 4\"";
        _ = try std.testing.expectEqualStrings(res, answer);
    }
    {
        const res = try getField(alloc, line, &start);
        defer alloc.free(res);
        const answer = "6";
        _ = try std.testing.expectEqualStrings(res, answer);
    }
}
