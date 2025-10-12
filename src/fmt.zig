const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const stdout = std.fs.File.stdout;
const json = std.json;

// TODO: pass in separator here
pub fn parseDynamicValue(alloc: Allocator, s: []const u8) !json.Value {
    if (s.len == 0 or std.mem.eql(u8, s, "null")) {
        return json.Value{ .null = {} };
    }

    // bools
    if (std.mem.eql(u8, s, "true")) {
        return json.Value{ .bool = true };
    } else if (std.mem.eql(u8, s, "false")) {
        return json.Value{ .bool = false };
    }

    // nums
    if (std.fmt.parseInt(i64, s, 10)) |int_val| {
        return json.Value{ .integer = int_val };
    } else |_| {}

    if (std.fmt.parseFloat(f64, s)) |float_val| {
        return json.Value{ .float = float_val };
    } else |_| {}

    if (s[0] == '[' and s[s.len - 1] == ']') {
        const slice = s[1 .. s.len - 1];
        var items = try std.ArrayList(json.Value).initCapacity(alloc, 10);
        var values = std.mem.splitAny(u8, slice, ",");

        while (values.next()) |x| {
            const val = parseDynamicValue(alloc, x) catch continue;
            items.append(alloc, val) catch continue;
        }

        return json.Value{ .array = items.toManaged(alloc) };
    }
    // if (s[0] == '{' and s[s.len - 1] == '}') {
    // TODO: implement object parsing
    // }

    return json.Value{ .string = s };
}

pub fn getField(alloc: Allocator, line: []const u8, sep: u8, start_pos: *usize) ![]const u8 {
    if (line.len == 0 or start_pos.* >= line.len) return error.OutOfBounds;

    const slice = line[start_pos.*..];
    var buf = try alloc.alloc(u8, slice.len);
    var idx: usize = 0;
    var in_quotes = false;

    for (slice) |c| {
        if (c == '"') {
            in_quotes = !in_quotes;
            continue;
        }
        if (c == sep and !in_quotes) break;
        if (c == '\n' or c == '\r') break;
        buf[idx] = c;
        idx += 1;
    }

    start_pos.* += idx + 1;
    const trimmed = std.mem.trim(u8, buf[0..idx], " \r\n");

    const result = try alloc.alloc(u8, trimmed.len);
    @memcpy(result, trimmed);

    alloc.free(buf);
    return result;
}

test "get field" {
    const alloc = std.testing.allocator;
    const line = "giraffe,dog,cat,\"[alligator, crocodile]\"";
    const sep = ',';

    var start: usize = 0;
    var answer = try getField(alloc, line, sep, &start);
    _ = &answer;
    defer alloc.free(answer);

    const expected = "giraffe";

    try expect(std.mem.eql(u8, answer, expected));
    try expect(start == 8);
}
