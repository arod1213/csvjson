const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const ArrayList = std.ArrayList;

const xsv = @import("xsv_reader");
const input = xsv.args.ReadArgs();
const types = xsv.types;
const link = xsv.link;
const write = xsv.write;

pub fn read_types(alloc: Allocator, csv: *xsv.CSVReader, writer: *std.Io.Writer, args: *const input) !void {
    var type_map = std.StringHashMap(*ArrayList([]const u8)).init(alloc);
    defer type_map.deinit();

    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        const obj = csv.next() catch break;
        types.save_types(alloc, &type_map, obj) catch {
            continue;
        };
    }

    const map = try types.flatten_type_map(alloc, type_map);
    var obj = try link.mapToObject([]const u8, alloc, map);
    const json_obj = std.json.Value{ .object = obj };

    try write.stringify(writer, &json_obj, args.minified);
    obj.deinit();

    try writer.flush();
}
