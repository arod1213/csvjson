const std = @import("std");
const csvjson = @import("csvjson");
const stdin = std.fs.File.stdin;
const cli = csvjson.cli;
const print = std.debug.print;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in = stdin();
    var stdout = std.fs.File.stdout();
    var out = std.Io.Writer.Allocating.init(alloc);
    defer out.clearRetainingCapacity();

    const args = try cli.Args().init();
    var csv_reader = try csvjson.CSVReader.init(alloc, &in, &args);

    _ = try stdout.write("[");
    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        const json_str = csv_reader.next(&out) catch break;
        _ = try stdout.write(json_str);
        // TODO: strip last comma
        _ = try stdout.write(",\n");
    }
    _ = try stdout.write("]");
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
