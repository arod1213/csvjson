const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = std.debug.assert;
const expect = std.testing.expect;
const array = std.ArrayList;
const json = std.json;

const xsv = @import("xsv_reader");
const args = @import("./args.zig");
const ReadType = xsv.args.ReadType;
const ReadArgs = xsv.args.ReadArgs();
const types = xsv.types;
const link = xsv.link;
const write = xsv.write;

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

pub fn help() void {
    print("-f: list of files to read from (only valid for -r key)\n", .{});
    print("-r: read type [all, type, key, field]\n", .{});

    print("-n: field name to search for (only valid for -r field)\n", .{});

    print("-l: total lines to read\n", .{});
    print("-o: line offset to start reading from\n", .{});
    print("-m: if enabled, print minimized jsonl\n", .{});
}

pub fn errorMsg(msgs: []const []const u8) void {
    for (msgs) |msg| {
        print("{s}\n", .{msg});
    }
}

pub const OSArgs = struct {
    offset: usize = 0,
    line_count: ?usize = null,
    minified: bool = false,
    separator: u8 = ',',
    read_type: ReadType = .all,

    field_name: ?[][]const u8 = null,
    files: ?ArrayList([]const u8) = null,

    const Self = @This();

    pub fn fromArgs(alloc: Allocator) !Self {
        var self = OSArgs{};

        const input = try args.argsToMap(alloc);

        // print help messages
        if (input.get("-h") != null) {
            help();
            std.process.exit(0);
        }

        self.files = try args.parseField(alloc, []const u8, &input, "-f");
        {
            const x = args.parseField(alloc, ReadType, &input, "-r") catch {
                errorMsg(&.{
                    "Error: read type could not be parsed",
                    "Valid options: all | types | keys",
                });
                std.process.exit(0);
            };
            if (x.items.len > 0) self.read_type = x.items[0];
        }
        {
            const x = args.parseField(alloc, usize, &input, "-o") catch {
                errorMsg(&.{"Error: offset is not an int"});
                std.process.exit(0);
            };
            if (x.items.len > 0) self.offset = x.items[0];
        }

        {
            const x = args.parseField(alloc, usize, &input, "-l") catch {
                errorMsg(&.{"Error: line count is not an int"});
                std.process.exit(0);
            };
            if (x.items.len > 0) self.line_count = x.items[0];
        }

        {
            var x = args.parseField(alloc, []const u8, &input, "-n") catch {
                errorMsg(&.{"Error: field name must be a string"});
                std.process.exit(0);
            };
            if (x.items.len > 0) self.field_name = try x.toOwnedSlice(alloc);
        }

        {
            self.minified = if (input.get("-m") == null) false else true;
        }

        {
            const x = args.parseField(alloc, []const u8, &input, "-s") catch {
                errorMsg(&.{"Error: separator is not a valid character"});
                std.process.exit(0);
            };
            if (x.items.len > 0) {
                assert(x.items[0].len != 0);
                if (x.items[0].len != 1) {
                    errorMsg(&.{"Error: separator must be a single character"});
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
