const std = @import("std");
const csvjson = @import("csvjson");
const stdin = std.fs.File.stdin;
const cli = csvjson.cli;
const print = std.debug.print;
const write = csvjson.write;
const Allocator = std.mem.Allocator;

fn parse_csv(arena: *std.heap.ArenaAllocator, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    const alloc = arena.allocator();
    defer {
        _ = arena.reset(.retain_capacity);
    }

    const args = try cli.Args().init();
    var csv_reader = try csvjson.CSVReader.init(alloc, reader, &args);
    defer csv_reader.deinit();

    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        var obj = csv_reader.next() catch break;
        const json_obj = std.json.Value{ .object = obj };

        try write.stringify(writer, &json_obj, args.minified);
        _ = try writer.writeByte('\n');
        obj.deinit();
    }

    try writer.flush();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var in_buf: [4096 * 10]u8 = undefined;
    const cwd = std.fs.cwd();
    var file = try cwd.openFile("aidan.csv", .{});
    var reader = file.reader(&in_buf);

    var out_buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&out_buf);
    try parse_csv(&arena, &reader.interface, &writer.interface);
}

// TODO: this test just hangs ??
// test "leaks" {
//     const alloc = std.testing.allocator;
//
//     var in_buf: [4096 * 10]u8 = undefined;
//     const cwd = std.fs.cwd();
//     var file = try cwd.openFile("aidan.csv", .{});
//     var reader = file.reader(&in_buf);
//
//     var out_buf: [4096]u8 = undefined;
//     var writer = std.fs.File.stdout().writer(&out_buf);
//     try parse_csv(alloc, &reader.interface, &writer.interface);
// }
