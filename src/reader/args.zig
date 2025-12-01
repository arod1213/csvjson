const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const json = std.json;

pub const ReadType = enum { all, type, key, field };
pub fn ReadArgs() type {
    return struct {
        offset: usize = 0,
        line_count: ?usize = null,
        minified: bool = false,
        separator: u8 = ',',
        read_type: ReadType = .all,
        field_names: ?[][]const u8 = null,
    };
}
