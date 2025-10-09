const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const read = @import("read.zig");
const array = std.ArrayList;
const json = std.json;

// TODO: return struct with useful args
//
pub fn Args() type {
    return struct {
        offset: usize = 0,
        line_count: ?usize = null, // null for file read
        minified: bool = false,

        pub fn init() !@This() {
            var self = @This(){};
            const args = std.os.argv;

            // TODO: make this windowed (2 args at a time)
            for (args) |arg| {
                const text: []const u8 = std.mem.span(arg);
                if (text.len < 2 or text[0] != '-') continue;

                const flag = text[1];
                const eq_index = std.mem.indexOfScalar(u8, text, '=');
                const value = if (eq_index) |i| text[i + 1 ..] else "";

                switch (flag) {
                    'o', 'O' => self.offset = try std.fmt.parseInt(usize, value, 10),
                    'l', 'L' => self.line_count = try std.fmt.parseInt(usize, value, 10),
                    'm', 'M' => self.minified = true,
                    else => {},
                }
            }

            return self;
        }
    };
}
