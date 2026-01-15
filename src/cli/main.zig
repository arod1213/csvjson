const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const log = std.log;

const xsv = @import("xsv_reader");
const parser = @import("./parse.zig");
const help = @import("./help.zig");
const ReadType = xsv.args.ReadType;
const ReadArgs = xsv.args.ReadArgs();
const types = xsv.types;
const link = xsv.link;
const write = xsv.write;

pub const OSArgs = struct {
    offset: usize = 0,
    line_count: ?usize = null,
    minified: bool = false,
    separator: u8 = ',',
    read_type: ReadType = .all,

    field_name: ?[][]const u8 = null,
    files: ?[][]const u8 = null,

    const Self = @This();

    pub fn fromArgs(alloc: Allocator) !Self {
        var self = OSArgs{};

        const input = try parser.argsToMap(alloc);

        // print help messages
        if (input.get("-h") != null) {
            help.help();
            std.process.exit(0);
        }

        self.files = blk: {
            var x = try parser.parseField(alloc, []const u8, &input, "-f");
            break :blk try x.toOwnedSlice(alloc);
        };
        {
            const x = parser.parseField(alloc, ReadType, &input, "-r") catch {
                var options = try std.ArrayList(u8).initCapacity(alloc, 15);
                defer options.deinit(alloc);

                const info = @typeInfo(ReadType);
                inline for (info.@"enum".fields, 0..) |f, i| {
                    if (i != 0) {
                        try options.appendSlice(alloc, " | ");
                    }
                    try options.appendSlice(alloc, f.name);
                }
                const option_list = try options.toOwnedSlice(alloc);

                help.errorMsg(&.{
                    "Error: read type could not be parsed",
                    // "Valid options: all | type | keys",
                    option_list,
                });
                std.process.exit(0);
            };
            if (x.items.len > 0) self.read_type = x.items[0];
        }
        {
            const x = parser.parseField(alloc, usize, &input, "-o") catch {
                help.errorMsg(&.{"Error: offset is not an int"});
                std.process.exit(0);
            };
            if (x.items.len > 0) self.offset = x.items[0];
        }

        {
            const x = parser.parseField(alloc, usize, &input, "-l") catch {
                help.errorMsg(&.{"Error: line count is not an int"});
                std.process.exit(0);
            };
            if (x.items.len > 0) self.line_count = x.items[0];
        }

        {
            var x = parser.parseField(alloc, []const u8, &input, "-n") catch {
                help.errorMsg(&.{"Error: field name must be a string"});
                std.process.exit(0);
            };
            if (x.items.len > 0) self.field_name = try x.toOwnedSlice(alloc);
        }

        {
            self.minified = if (input.get("-m") == null) false else true;
        }

        {
            const x = parser.parseField(alloc, []const u8, &input, "-s") catch {
                help.errorMsg(&.{"Error: separator is not a valid character"});
                std.process.exit(0);
            };
            if (x.items.len > 0) {
                assert(x.items[0].len != 0);
                if (x.items[0].len != 1) {
                    help.errorMsg(&.{"Error: separator must be a single character"});
                    std.process.exit(0);
                }
                self.separator = x.items[0][0];
            }
        }

        return self;
    }
    pub fn into_reader_args(self: @This()) ReadArgs {
        return ReadArgs{
            .minified = self.minified,
            .line_count = self.line_count,
            .read_type = self.read_type,
            .separator = self.separator,
            .offset = self.offset,
            .field_names = self.field_name,
        };
    }
};
