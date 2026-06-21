const std = @import("std");
const print = std.debug.print;
const Io = std.Io;

const my_ls = @import("my_ls");

const Command = enum {
    list_all,
    list_details,
};

const command_map = std.StaticStringMap(Command).initComptime(.{
    .{ "-a", .list_all },
    .{ "-l", .list_details },
});

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    var ls_current_dir: bool = false;
    if (args.len < 2) {
        print("Program usage:   {s} <flags>\n", .{args[0]});
        return;
    }

    var flags: [][]const u8 = try allocator.alloc([]const u8, args.len - 1);
    const is_flags: bool = if (args.len >= 2) true else false;
    if (is_flags) {
        _ = getFlags(&flags, args);
    }

    if (is_flags and compareStrArgs(args[1], flags[0])) {
        ls_current_dir = true;
    }

    var dir: std.Io.Dir = undefined;
    if (ls_current_dir) {
        dir = std.Io.Dir.cwd();
    } else {
        if (args[1][0] == '/' or args[1][0] == '~') {
            dir = std.Io.Dir.openDirAbsolute(init.io, args[1], .{ .access_sub_paths = true, .iterate = true }) catch |err| switch (err) {
                error.FileNotFound => {
                    print("File not found\n", .{});
                    return;
                },
                else => return err,
            };
        } else {
            dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), init.io, args[1], .{ .access_sub_paths = true, .iterate = true }) catch |err| switch (err) {
                error.FileNotFound => {
                    print("File not found\n", .{});
                    return;
                },
                else => return err,
            };
        }
    }

    // here we access all files or directories inside dir
    // then based on flags we print properly output
    print("Is ls cwd: {}\n", .{ls_current_dir});

    const dir_data = try getDirectoryData(dir, allocator, init.io);

    for (dir_data.items) |dir_entry| {
        print("{s}\n", .{dir_entry});
    }
}

fn getFlags(flags: *[][]const u8, args: []const [:0]const u8) usize {
    var i: usize = 0;
    for (args) |arg| {
        if (arg[0] == '-') {
            flags.*[i] = arg;
            i += 1;
        }
    }
    return i;
}

fn compareStrArgs(str1: []const u8, str2: []const u8) bool {
    if (str1.len != str2.len) {
        return false;
    }
    for (str1, str2) |c1, c2| {
        if (c1 != c2) {
            return false;
        }
    }
    return true;
}

fn getDirectoryData(directory: std.Io.Dir, allocator: std.mem.Allocator, io: std.Io) !std.ArrayList([]const u8) {
    var sources = try std.ArrayList([]const u8).initCapacity(allocator, 4096);

    var iterator = directory.iterate();

    while (try iterator.next(io)) |entry| {
        const path_copy = try allocator.dupe(u8, entry.name);
        errdefer allocator.free(path_copy);
        try sources.append(allocator, path_copy);
    }
    return sources;
}
