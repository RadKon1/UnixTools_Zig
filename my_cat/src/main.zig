const std = @import("std");
const print = std.debug.print;

pub fn main(init: std.process.Init) !void {
    const stderr_writer = std.Io.File.stderr();

    const args = try init.minimal.args.toSlice(init.arena.allocator());
    print("args len: {d}", .{args.len});
    if (args.len != 2) {
        try stderr_writer.writeStreamingAll(init.io, "Program usage: <program name> <file_path>\n");
        return;
    }

    const cwd = std.Io.Dir.cwd();

    // open the file
    const file: std.Io.File = std.Io.Dir.openFile(cwd, init.io, args[1], .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => {
            print("File not found\n", .{});
            return;
        },
        else => return,
    };
    defer file.close(init.io);

    var read_buffer: [1024]u8 = undefined;
    var reader = file.reader(init.io, &read_buffer);
    var bytes_counter: u64 = 0;

    while (true) {
        const bytes_read = reader.interface.readSliceShort(&read_buffer) catch |err| switch (err) {
            error.ReadFailed => {
                print("Someting went wrong - failed to read from file", .{});
                return;
            },
        };
        bytes_counter += bytes_read;
        if (bytes_read == 0) {
            break;
        }
    }
    print("{s}", .{read_buffer[0..bytes_counter]});
    //
}
