const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const ArrayList = std.ArrayList;
const HashMap = std.StringHashMap;
const Value = std.json.Value;

const xsv = @import("xsv_reader");
const input = xsv.args.ReadArgs();
const types = xsv.types;
const link = xsv.link;
const write = xsv.write;

pub fn read_field(alloc: Allocator, writer: *std.Io.Writer, args: *const input, path: []const u8, fields: *const [][]const u8) !void {
    var file = try blk: {
        if (std.fs.path.isAbsolute(path)) {
            break :blk std.fs.openFileAbsolute(path, .{ .mode = .read_only });
        } else {
            const cwd = std.fs.cwd();
            break :blk cwd.openFile(path, .{ .mode = .read_only });
        }
    };
    var in_buf: [4096 * 5]u8 = undefined;
    var rdr = file.reader(&in_buf);

    var xsv_reader = try xsv.CSVReader.init(alloc, &rdr.interface, args);
    defer xsv_reader.deinit();

    const hd = try xsv_reader.next();
    const iter = hd.keys();

    var list = try ArrayList([]const u8).initCapacity(alloc, 5);
    defer list.deinit(alloc);

    for (fields.*) |field| {
        var found: bool = false;
        for (iter) |key| {
            if (std.mem.eql(u8, key, field)) {
                found = true;
            }
        }
        if (!found) {
            try list.append(alloc, field);
        }
    }

    const missed = try list.toOwnedSlice(alloc);
    const joined = try std.mem.join(alloc, " and ", missed);
    if (missed.len > 0) {
        const str = try std.fmt.allocPrint(alloc, "{s}: missing {s}\n", .{ path, joined });
        _ = try writer.write(str);
    }
}
