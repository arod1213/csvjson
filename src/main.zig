const std = @import("std");
const stdin = std.fs.File.stdin;
const print = std.debug.print;

const cli = @import("cli");
const xsv = @import("xsv_reader");
const commands = @import("commands");

const Allocator = std.mem.Allocator;
const Value = std.json.Value;
const ArrayList = std.ArrayList;
const HashMap = std.StringHashMap;

// TODO: support -f flag for all methods
// TODO: support cat piping for all methods

fn parse_csv(alloc: Allocator, writer: *std.Io.Writer) !void {
    const input = try cli.OSArgs.fromArgs(alloc);
    const args = input.into_reader_args();

    blk: switch (args.read_type) {
        .all => {
            var in_buf: [4096 * 5]u8 = undefined;
            var reader = std.fs.File.stdin().reader(&in_buf);

            var csv_reader = try xsv.CSVReader.init(alloc, &reader.interface, &args);
            defer csv_reader.deinit();

            try commands.read.read_vals(&csv_reader, writer, &args);
        },
        .field => {
            if (input.files == null or input.files.?.len == 0) {
                _ = try writer.write("Error: please provide files to read\n");
                break :blk;
            }
            for (input.files.?) |path| {
                if (args.field_names == null or args.field_names.?.len == 0) {
                    _ = try writer.write("Error: please provide a field name\n");
                    break :blk;
                }
                try commands.field.read_field(alloc, writer, &args, path, &args.field_names.?);
            }
        },
        .type => {
            var in_buf: [4096 * 5]u8 = undefined;
            var reader = std.fs.File.stdin().reader(&in_buf);

            var csv_reader = try xsv.CSVReader.init(alloc, &reader.interface, &args);
            defer csv_reader.deinit();
            try commands.types.read_types(alloc, &csv_reader, writer, &args);
        },
        .key => {
            if (input.files == null or input.files.?.len == 0) {
                _ = try writer.write("Error: please provide files to read\n");
                break :blk;
            }

            const files = input.files.?;
            var map = HashMap(usize).init(alloc);
            defer map.deinit();

            for (files) |path| {
                try commands.unique.read_keys(alloc, &args, path, &map);
            }

            var iter = map.iterator();
            while (iter.next()) |set| {
                const key, const val = .{ set.key_ptr, set.value_ptr };
                const limit = if (args.line_count) |l| l else files.len;
                if (val.* < limit) {
                    _ = map.remove(key.*);
                }
            }
            var obj = try xsv.link.mapToObject(usize, alloc, &map);
            defer obj.deinit();
            const json_obj = std.json.Value{ .object = obj };
            try xsv.write.stringify(writer, &json_obj, args.minified);
        },
    }

    try writer.flush();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var out_buf: [4096]u8 = undefined;
    var writer = std.fs.File.stdout().writer(&out_buf);
    try parse_csv(alloc, &writer.interface);
}
