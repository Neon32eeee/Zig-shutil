const std = @import("std");

pub const CmdSettings = struct { allocator: std.mem.Allocator = std.heap.page_allocator, max_buffer_size: usize = 4096 };

// Defining custom error types for the library
pub const ShutilError = error{ ProcessFailed, InvalidPath, NoStdout, CommandNotFound, UserNotFound, InvalidArg, UserNotArg };

// Executes a shell command and streams its output to stdout/stderr
pub fn CmdCall(settings: CmdSettings, command: []const []const u8) !void {
    // Check if the command is empty
    if (command.len == 0) return ShutilError.CommandNotFound;

    // Initialize a child process with the given command and allocator
    var child = std.process.Child.init(command, settings.allocator);

    // Configure the child process to pipe stdout, stderr, and stdin
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    child.stdin_behavior = .Pipe;

    // Spawn the child process
    try child.spawn();

    // Ensure pipes are closed after function execution
    defer if (child.stdout) |*pipe| pipe.close();
    defer if (child.stderr) |*pipe| pipe.close();
    defer if (child.stdin) |*pipe| pipe.close();

    // Buffer for reading output
    const buffer = try settings.allocator.alloc(u8, settings.max_buffer_size);
    defer settings.allocator.free(buffer);

    // Get standard output and error writers
    const stdout_writer = std.io.getStdOut().writer();
    const stderr_writer = std.io.getStdErr().writer();

    // Read and write stdout to the console
    if (child.stdout) |pipe| {
        while (true) {
            const bytes_read = try pipe.read(buffer);
            if (bytes_read == 0) break;
            try stdout_writer.writeAll(buffer[0..bytes_read]);
        }
    } else {
        return ShutilError.NoStdout;
    }

    // Read and write stdout to the console
    if (child.stderr) |pipe| {
        while (true) {
            const bytes_read = try pipe.read(buffer);
            if (bytes_read == 0) break;
            try stderr_writer.writeAll(buffer[0..bytes_read]);
        }
    }

    // Wait for the process to complete and check its exit status
    const term = try child.wait();
    if (term.Exited != 0) {
        std.debug.print("Command failed with status {d}:", .{term.Exited});
        for (command) |arg| {
            std.debug.print(" {s}", .{arg});
        }
        std.debug.print("\n", .{});
        return ShutilError.ProcessFailed;
    }
}

// Executes a shell command and returns its stdout as a string
pub fn CmdCallAndReturn(settings: CmdSettings, command: []const []const u8) ![]const u8 {
    // Initialize a child process with the given command and allocator
    var child = std.process.Child.init(command, settings.allocator);

    // Configure the child process to pipe stdout and stderr
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    // Spawn the child process
    try child.spawn();

    // Ensure pipes are closed after function execution
    defer if (child.stdout) |*pipe| pipe.close();
    defer if (child.stderr) |*pipe| pipe.close();

    // Read the entire stdout into a buffer
    const stdout = if (child.stdout) |pipe| try pipe.readToEndAlloc(settings.allocator, settings.max_buffer_size) else return ShutilError.NoStdout;

    // Read the entire stderr into a buffer
    const stderr = if (child.stderr) |pipe| try pipe.readToEndAlloc(settings.allocator, settings.max_buffer_size) else &[_]u8{};
    defer if (child.stderr != 0) settings.allocator.free(stderr);
    if (stderr.len > 0) {
        std.debug.print("Error: {s}\n", .{stderr});
    }

    // Wait for the process to complete and check its exit status
    const term = try child.wait();
    if (term.Exited != 0) {
        if (stderr.len > 0) std.debug.print("Error: {s}\n", .{stderr});
        return ShutilError.ProcessFailed;
    }

    // Trim whitespace from the output
    const trimmed = std.mem.trim(u8, stdout, " \n\r\t");
    if (trimmed.len == 0) {
        settings.allocator.free(stdout);
        return ShutilError.UserNotFound;
    }

    // Duplicate the trimmed output for return
    const result = try settings.allocator.dupe(u8, trimmed);
    settings.allocator.free(stdout);
    return result;
}
