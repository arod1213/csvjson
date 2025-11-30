const std = @import("std");
const stdin = std.fs.File.stdin;
const print = std.debug.print;

const cli = @import("cli");
const xsv = @import("xsv_reader");
const commands = @import("commands");

const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const ArrayList = std.ArrayList;

fn parse_csv(alloc: Allocator, reader: *std.Io.Reader, writer: *std.Io.Writer) !void {
    const input = try cli.Args.fromArgs(alloc);
    const args = input.into_reader_args();

    // const args = try xsv.args.Args().fromArgs();
    var csv_reader = try xsv.CSVReader.init(alloc, reader, &args);
    defer csv_reader.deinit();

    switch (args.read_type) {
        .All => try commands.read.read_vals(&csv_reader, writer, &args),
        .Types => try commands.types.read_types(alloc, &csv_reader, writer, &args),
        .Keys => unreachable,
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
