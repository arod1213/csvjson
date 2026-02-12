const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const ArrayList = std.ArrayList;

const xsv = @import("xsv_reader");
const ReadArgs = xsv.Args;

pub fn read_types(alloc: Allocator, csv: *xsv.CSVReader, writer: *std.Io.Writer, args: *const ReadArgs) !void {
    var type_map = std.StringHashMap(*ArrayList([]const u8)).init(alloc);
    defer type_map.deinit();

    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        const obj = csv.next(alloc) catch break;
        const json_obj = try xsv.strMapToJson(alloc, &obj);
        xsv.saveTypes(alloc, &type_map, json_obj) catch {
            continue;
        };
    }

    const map = try xsv.flattenTypeMap(alloc, type_map);
    var obj = try xsv.mapToObject([]const u8, alloc, map);
    const json_obj = std.json.Value{ .object = obj };

    try xsv.stringify(writer, &json_obj, args.minified);
    obj.deinit();

    try writer.flush();
}
