const std = @import("std");
const print = std.debug.print;

const Command = enum {
    num_lines,
    non_blank_lines,
};

const FlagStruct = struct {
    count_lines: bool = false,
    count_blank: bool = false,
};

const command_map = std.StaticStringMap(Command).initComptime(.{
    .{ "-b", .non_blank_lines },
    .{ "-n", .num_lines },
});

pub fn main(init: std.process.Init) !void {
    const stderr_writer = std.Io.File.stderr();
    const cwd = std.Io.Dir.cwd();
    var flags: [][]const u8 = undefined;

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        try stderr_writer.writeStreamingAll(init.io, "Program usage: <program name> <file_path> -<flags: n>\n");
        return;
    }

    const is_flags: bool = try flagsPresent(args.len, init, args, &flags);

    // open the file
    const file: std.Io.File = std.Io.Dir.openFile(cwd, init.io, args[1], .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => {
            print("File not found\n", .{});
            return;
        },
        else => return err,
    };
    defer file.close(init.io);

    const read_buffer: []u8 = try std.heap.page_allocator.alloc(u8, 1024 * 1024);
    defer std.heap.page_allocator.free(read_buffer);

    var reader = file.reader(init.io, read_buffer);
    try readFile(&reader, read_buffer, is_flags, &flags);
}

// flag -n is of higher priority than -b
fn readFile(reader: anytype, buffer: []u8, is_flags: bool, flags: *[][]const u8) !void {
    var flagStruct: FlagStruct = .{};
    if (is_flags) {
        flagStruct = analyzeFlags(flags);
    }

    var line_number: usize = 1;
    var at_line_start: bool = true;

    while (true) {
        const bytes_read = reader.interface.readSliceShort(buffer) catch |err| switch (err) {
            error.ReadFailed => {
                print("Someting went wrong - failed to read from file\n", .{});
                return err;
            },
        };

        if (bytes_read == 0) {
            break;
        }

        const chunk = buffer[0..bytes_read];

        for (chunk) |byte| {
            if (at_line_start) {
                if (flagStruct.count_lines) {
                    print("{d:6}\t", .{line_number});
                    line_number += 1;
                } else if (flagStruct.count_blank and byte != '\n') {
                    print("{d:6}\t", .{line_number});
                    line_number += 1;
                }
                at_line_start = false;
            }

            print("{c}", .{byte});

            if (byte == '\n') {
                at_line_start = true;
            }
        }
    }
}

fn analyzeFlags(flags: *[][]const u8) FlagStruct {
    var flagStruct: FlagStruct = .{};
    for (flags.*) |flag| {
        if (command_map.get(flag)) |enum_flag| {
            switch (enum_flag) {
                .num_lines => flagStruct.count_lines = true,
                .non_blank_lines => flagStruct.count_blank = true,
            }
        } else {
            print("did not find flag {any}", .{flag});
            continue;
        }
    }
    return flagStruct;
}

fn flagsPresent(args_len: usize, init: std.process.Init, args: []const [:0]const u8, flags: *[][]const u8) !bool {
    if (args_len > 2) {
        const flags_count = args_len - 2;

        flags.* = try init.arena.allocator().alloc([]const u8, flags_count);

        var i: usize = 0;
        while (i < flags_count) : (i += 1) {
            flags.*[i] = args[2 + i][0..];
        }

        return true;
    } else {
        return false;
    }
}
