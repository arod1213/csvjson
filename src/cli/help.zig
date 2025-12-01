const std = @import("std");
const print = std.debug.print;

pub fn help() void {
    print("-f: list of files to read from (only valid for -r key)\n", .{});
    print("-r: read type [all, type, key, field]\n", .{});

    print("-n: field name to search for (only valid for -r field)\n", .{});

    print("-l: total lines to read\n", .{});
    print("-o: line offset to start reading from\n", .{});
    print("-m: if enabled, print minimized jsonl\n", .{});
}

pub fn errorMsg(msgs: []const []const u8) void {
    for (msgs) |msg| {
        print("{s}\n", .{msg});
    }
}
