const std = @import("std");

const print = std.debug.print;
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const expect = std.testing.expect;
const ArrayList = std.ArrayList;
const HashMap = std.StringHashMap;

const xsv = @import("xsv_reader");
const types = xsv.types;
const link = xsv.link;
const write = xsv.write;

// pub fn read_keys(alloc: Allocator, writer: *std.Io.Writer, args: *const xsv.Args()) !void {
//     var map = try HashMap(usize).init(alloc);
//
//     const cwd = std.fs.cwd();
//     for (file_paths.items) |path| {
//         var file = cwd.openFile(path, .{ .mode = .read_only }) catch {
//             continue;
//         };
//     }
// }
