const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const json = std.json;

pub fn parseSeparator(value: []const u8) u8 {
    assert(value.len > 0);
    if (std.mem.eql(u8, value, "comma")) {
        return ',';
    } else if (std.mem.eql(u8, value, "tab")) {
        return '\t';
    } else {
        return value[0];
    }
}

pub const ReadType = enum { all, types, keys };
pub fn Args() type {
    return struct {
        offset: usize = 0,
        line_count: ?usize = null,
        minified: bool = false,
        separator: u8 = ',',
        read_type: ReadType = .all,
    };
}
