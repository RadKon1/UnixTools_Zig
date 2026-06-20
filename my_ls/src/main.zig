const std = @import("std");
const panic = std.debug.panic;
const print = std.debug.print;
const Io = std.Io;

const my_ls = @import("my_ls");

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        print("Program usage:   {s} <flags>\n", .{args[0]});
        return;
    }

    // and here we do some fancy shit with getting the directory and showing all its contents
    // const cwd = Io.Dir.cwd();
    var flags: [][]const u8 = try allocator.alloc([]const u8, args.len - 1);
    const is_flags: bool = if (args.len >= 2) true else false;
    if (is_flags) {
        const flag_amount: usize = getFlags(&flags, args);
        print("====== PRINTING FLAGS ======\n", .{});
        for (0..flag_amount) |i| {
            print("{s}\n", .{flags[i]});
        }
    }
}

fn getFlags(flags: *[][]const u8, args: []const [:0]const u8) usize {
    var i: usize = 0;
    for (args) |arg| {
        if (arg[0] != '-') {
            print("coninuing...\n", .{});
            continue;
        } else {
            flags.*[i] = arg;
            i += 1;
            print("Adding a flag...\n", .{});
        }
    }
    return i;
}
