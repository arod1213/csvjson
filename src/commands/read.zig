const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const ArrayList = std.ArrayList;

const xsv = @import("xsv_reader");
const ReadArgs = xsv.Args;

pub fn read_vals(alloc: Allocator, csv: *xsv.CSVReader, writer: *std.Io.Writer, args: *const ReadArgs) !void {
    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        var obj = csv.next(alloc) catch break;
        const obj_as_json = try xsv.strMapToJson(alloc, &obj);
        const json_obj = std.json.Value{ .object = obj_as_json };

        try xsv.stringify(writer, &json_obj, args.minified);
        _ = try writer.writeByte('\n');
        obj.deinit();
    }
}
