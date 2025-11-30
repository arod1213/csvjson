const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const ArrayList = std.ArrayList;

const xsv = @import("xsv_reader");
const types = xsv.types;
const link = xsv.link;
const write = xsv.write;

pub fn read_vals(csv: *xsv.CSVReader, writer: *std.Io.Writer, args: *const xsv.Args()) !void {
    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        var obj = csv.next() catch break;
        const json_obj = std.json.Value{ .object = obj };

        try write.stringify(writer, &json_obj, args.minified);
        _ = try writer.writeByte('\n');
        obj.deinit();
    }
}
