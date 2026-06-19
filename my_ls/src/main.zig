const std = @import("std");
const panic = std.debug.panic;
const print = std.debug.print;
const Io = std.Io;

const my_ls = @import("my_ls");

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        print("Program usage:   {s} <flags>\n", .{args[0]});
        return;
    }

    // and here we do some fancy shit with getting the directory and showing all its contents
    // const cwd = Io.Dir.cwd();
    var flags: [][]const u8 = undefined;
    const is_flags: bool = if (args.len > 2) true else false;
    if (is_flags) {
        getFlags(&flags, &args);
    }

    //

    //
    //

}

fn getFlags(flags: *[][]const u8, args: *[]const [:0]const u8) !void {
    //
    //
    for (args.*, 0..) |arg, i| {
        if (arg[0] != '-') {
            continue;
        } else {
            flags[i] = arg;
        }
    }
}
