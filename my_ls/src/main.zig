const std = @import("std");
const print = std.debug.print;
const Io = std.Io;

const my_ls = @import("my_ls");

const Command = enum {
    list_all,
    list_details,
};

const CommandBool = struct {
    l_all: bool,
    l_det: bool,
};

const command_map = std.StaticStringMap(Command).initComptime(.{
    .{ "-a", .list_all },
    .{ "-l", .list_details },
});

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;
    var is_ls_cwd: bool = true;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        print("Program usage:   {s} <flags>\n", .{args[0]});
        return;
    }

    var flag_bools: CommandBool = undefined;
    var flags: [][]const u8 = try allocator.alloc([]const u8, args.len - 1);
    const is_flags: bool = if (args.len >= 2) true else false;
    if (is_flags) {
        _ = getFlags(&flags, args, &flag_bools);
        is_ls_cwd = stringsEqual(args[1], flags[0]);
    }

    var dir = std.Io.Dir.cwd().openDir(init.io, ".", .{ .access_sub_paths = true, .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            print("File not found\n", .{});
            return;
        },
        else => return err,
    };

    if (!is_ls_cwd) {
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
    defer dir.close(init.io);

    const dir_data = try getDirectoryData(dir, allocator, init.io);

    try printData(dir_data, flag_bools);
}

fn getFlags(flags: *[][]const u8, args: []const [:0]const u8, flag_bools: *CommandBool) usize {
    var i: usize = 0;
    for (args) |arg| {
        if (arg[0] == '-') {
            flags.*[i] = arg;
            i += 1;
            if (command_map.get(arg) == .list_all) {
                flag_bools.l_all = true;
            } else if (command_map.get(arg) == .list_details) {
                flag_bools.l_det = true;
            }
        }
    }
    return i;
}

const FileData = struct {
    is_file: bool,
    permissions: std.Io.File.Permissions,
    links: std.Io.File.NLink,
    owner: []const u8,
    group: []const u8,
    size: u64,
    last_modification: std.Io.Timestamp,
    filename: []const u8,
};

fn getDirectoryData(directory: std.Io.Dir, allocator: std.mem.Allocator, io: std.Io) !std.ArrayList(FileData) {
    var sources = try std.ArrayList(FileData).initCapacity(allocator, 4096);

    var iterator = directory.iterate();

    while (try iterator.next(io)) |entry| {
        const fileStat: std.Io.File.Stat = try std.Io.Dir.statFile(directory, io, entry.name, .{ .follow_symlinks = false });
        const is_a_file: bool = entry.kind == .file;
        const file_data = FileData{ .is_file = is_a_file, .permissions = fileStat.permissions, .size = fileStat.size, .links = fileStat.nlink, .owner = "<owner>", .group = "<group>", .last_modification = fileStat.mtime, .filename = try allocator.dupe(u8, entry.name) };
        try sources.append(allocator, file_data);
    }
    return sources;
}

// todo - get the time, correct group and owner, also adjust padding, sorting the files is also needed.

fn printData(data: std.ArrayList(FileData), flag_bools: CommandBool) !void {
    if (flag_bools.l_det) {
        for (data.items) |file_data| {
            try printEntryDetailed(file_data, flag_bools.l_all);
        }
        return;
    }
    for (data.items) |file_data| {
        printEntryNormal(file_data.filename, flag_bools.l_all);
    }
}

fn printEntryDetailed(entry: FileData, l_all: bool) !void {
    if (!l_all and entry.filename[0] == '.') {
        return;
    }
    const first_char: u8 = if (entry.is_file) '-' else 'd';
    const permission_str: [9]u8 = formatPermissions(entry.permissions.toMode());
    // var format_buffer: [14]u8 = undefined;
    const last_mod_str: []const u8 = "dummy_date: Jan 09:22";

    print("{u}{s}@temp {} {s} {s} {d:>5} {s} {s} \n", .{ first_char, permission_str, entry.links, entry.owner, entry.group, entry.size, last_mod_str, entry.filename });
}

pub fn formatPermissions(mode: std.posix.mode_t) [9]u8 {
    var buf: [9]u8 = undefined;

    buf[0] = if (mode & 0o400 != 0) 'r' else '-';
    buf[1] = if (mode & 0o200 != 0) 'w' else '-';
    buf[2] = if (mode & 0o100 != 0) 'x' else '-';

    buf[3] = if (mode & 0o040 != 0) 'r' else '-';
    buf[4] = if (mode & 0o020 != 0) 'w' else '-';
    buf[5] = if (mode & 0o010 != 0) 'x' else '-';

    buf[6] = if (mode & 0o004 != 0) 'r' else '-';
    buf[7] = if (mode & 0o002 != 0) 'w' else '-';
    buf[8] = if (mode & 0o001 != 0) 'x' else '-';

    return buf;
}

fn printEntryNormal(entry: []const u8, l_all: bool) void {
    if (l_all) {
        print("{s} ", .{entry});
        return;
    }
    if (entry[0] != '.') {
        print("{s} ", .{entry});
    }
}

fn stringsEqual(str1: []const u8, str2: []const u8) bool {
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
