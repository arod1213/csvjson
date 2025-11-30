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

        pub fn default() !@This() {
            return @This(){};
        }

        pub fn fromArgs() !@This() {
            var self = @This(){};
            const args = std.os.argv;

            // TODO: make this windowed (2 args at a time)
            for (args) |arg| {
                const text: []const u8 = std.mem.span(arg);
                if (text.len < 2 or text[0] != '-') continue;

                const flag = std.ascii.toLower(text[1]);
                const eq_index = std.mem.indexOfScalar(u8, text, '=');
                const value = if (eq_index) |i| text[i + 1 ..] else "";

                switch (flag) {
                    'o' => self.offset = try std.fmt.parseInt(usize, value, 10),
                    'l' => self.line_count = try std.fmt.parseInt(usize, value, 10),
                    'm' => self.minified = true,
                    's' => self.separator = parseSeparator(value),
                    'r' => {
                        self.read_type = if (std.meta.stringToEnum(ReadType, value)) |v| v else .all;
                    },
                    else => {},
                }
            }

            return self;
        }
    };
}
