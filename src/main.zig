const std = @import("std");
const csvjson = @import("csvjson");
const stdin = std.fs.File.stdin;
const cli = csvjson.cli;
const link = csvjson.link;
const print = std.debug.print;
const types = csvjson.types;
const write = csvjson.write;
const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const ArrayList = std.ArrayList;

fn read_vals(csv: *csvjson.CSVReader, writer: *std.Io.Writer, args: *const cli.Args()) !void {
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

fn read_types(alloc: Allocator, csv: *csvjson.CSVReader, writer: *std.Io.Writer, args: *const cli.Args()) !void {
    var list = try std.ArrayList(std.json.ObjectMap).initCapacity(alloc, 10);
    defer {
        list.deinit(alloc);
    }

    var idx: usize = 0;
    while (true) : (idx += 1) {
        if (args.line_count) |lc| {
            if (idx >= lc) {
                break;
            }
        }
        const obj = csv.next() catch break;
        try list.append(alloc, obj);
    }

    const map = try types.parse_types(alloc, list);
    var obj = try link.mapToObject(alloc, map);
    const json_obj = std.json.Value{ .object = obj };

    try write.stringify(writer, &json_obj, args.minified);
    // _ = try writer.writeByte('\n');
    obj.deinit();

    try writer.flush();
}

fn parse_csv(alloc: Allocator, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    const args = try cli.Args().init();
    var csv_reader = try csvjson.CSVReader.init(alloc, reader, &args);
    defer csv_reader.deinit();

    if (args.types) {
        try read_types(alloc, &csv_reader, writer, &args);
    } else {
        try read_vals(&csv_reader, writer, &args);
    }

    try writer.flush();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var in_buf: [4096 * 5]u8 = undefined;
    var reader = std.fs.File.stdin().reader(&in_buf);

    var out_buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&out_buf);
    try parse_csv(alloc, &reader.interface, &writer.interface);
}
