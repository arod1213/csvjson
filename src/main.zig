const std = @import("std");
const csvjson = @import("csvjson");
const stdin = std.fs.File.stdin;
const cli = csvjson.cli;
const print = std.debug.print;
const write = csvjson.write;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    // var in = stdin();
    var in_buf: [4096]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buf);

    var out_buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&out_buf);
    defer writer.interface.flush() catch {};

    const args = try cli.Args().init();
    var csv_reader = try csvjson.CSVReader.init(alloc, &reader.interface, &args);

    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        const json_obj = csv_reader.next() catch break;

        try write.stringify(&writer.interface, &json_obj, args.minified);
        // TODO: strip last comma
        _ = try writer.interface.writeByte('\n');
    }
}

test "leaks" {
    const alloc = std.testing.allocator;
    const args = cli.Args().init();

    const cwd = std.fs.cwd();
    var in = try cwd.openFile("aidan.csv", .{});
    var stdout = std.fs.File.stdout();
    var out = std.Io.Writer.Allocating.init(alloc);

    var csv_reader = try csvjson.CSVReader.init(alloc, &in, &args);

    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx > lc) {
                break;
            }
        }
        const json_str = csv_reader.next(&out) catch break;
        _ = try stdout.write(json_str);
        _ = try stdout.write("\n");
    }
    out.clearRetainingCapacity();
}
