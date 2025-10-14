const std = @import("std");

const ShutilError = error{ ProcessFailed, InvalidPath, NoStdout, CommandNotFound, UserNotFound, InvalidArg };

fn CmdCall(alloc: std.mem.Allocator, command: []const []const u8) !void {
    if (command.len == 0) return ShutilError.CommandNotFound;

    var child = std.process.Child.init(command, alloc);

    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;
    child.stdin_behavior = .Pipe;

    try child.spawn();

    defer if (child.stdout) |*pipe| pipe.close();
    defer if (child.stderr) |*pipe| pipe.close();
    defer if (child.stdin) |*pipe| pipe.close();

    var buffer: [4096]u8 = undefined;

    const stdout_writer = std.io.getStdOut().writer();
    const stderr_writer = std.io.getStdErr().writer();

    if (child.stdout) |pipe| {
        while (true) {
            const bytes_read = try pipe.read(&buffer);
            if (bytes_read == 0) break; // Конец потока
            try stdout_writer.writeAll(buffer[0..bytes_read]);
        }
    } else {
        return ShutilError.NoStdout;
    }

    if (child.stderr) |pipe| {
        while (true) {
            const bytes_read = try pipe.read(&buffer);
            if (bytes_read == 0) break; // Конец потока
            try stderr_writer.writeAll(buffer[0..bytes_read]);
        }
    }

    const term = try child.wait();
    if (term.Exited != 0) {
        return ShutilError.ProcessFailed;
    }
}

fn CmdCallAndReturn(alloc: std.mem.Allocator, command: []const []const u8) ![]const u8 {
    var child = std.process.Child.init(command, alloc);

    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    defer if (child.stdout) |*pipe| pipe.close();
    defer if (child.stderr) |*pipe| pipe.close();

    const stdout = if (child.stdout) |pipe| try pipe.readToEndAlloc(alloc, 1024 * 1024) else return ShutilError.NoStdout;

    const stderr = if (child.stderr) |pipe| try pipe.readToEndAlloc(alloc, 1024 * 1024) else &[_]u8{};
    defer alloc.free(stderr);

    const term = try child.wait();
    if (term.Exited != 0) {
        if (stderr.len > 0) std.debug.print("Error: {s}\n", .{stderr});
        return ShutilError.ProcessFailed;
    }

    const trimmed = std.mem.trim(u8, stdout, " \n\r\t");
    if (trimmed.len == 0) {
        alloc.free(stdout);
        return ShutilError.UserNotFound;
    }

    const result = try alloc.dupe(u8, trimmed);
    alloc.free(stdout);
    return result;
}

pub const cmd = struct {
    pub const sudo = struct {
        pub fn run(alloc: std.mem.Allocator, command: []const u8) !void {
            const CommandTrimmed = [_][]const u8{ "sudo", "sh", "-c", command };
            try CmdCall(alloc, &CommandTrimmed);
        }
    };

    pub fn run(alloc: std.mem.Allocator, command: []const u8) !void {
        const CommandTrimmed = [_][]const u8{ "sh", "-c", command };
        try CmdCall(alloc, &CommandTrimmed);
    }

    pub fn cp(alloc: std.mem.Allocator, source: []const u8, target: []const u8) !void {
        if (source.len == 0 or target.len == 0) return ShutilError.InvalidPath;
        const command = [_][]const u8{ "cp", source, target };
        try CmdCall(alloc, &command);
    }

    pub fn mv(alloc: std.mem.Allocator, source: []const u8, target: []const u8) !void {
        if (source.len == 0 or target.len == 0) return ShutilError.InvalidPath;
        const command = [_][]const u8{ "mv", source, target };
        try CmdCall(alloc, &command);
    }

    pub fn mkdir(alloc: std.mem.Allocator, name: []const u8) !void {
        const command = [_][]const u8{ "mkdir", name };
        try CmdCall(alloc, &command);
    }

    pub fn touch(alloc: std.mem.Allocator, name: []const u8) !void {
        const command = [_][]const u8{ "touch", name };
        try CmdCall(alloc, &command);
    }

    pub fn cat(alloc: std.mem.Allocator, file: []const u8) !void {
        const command = [_][]const u8{ "cat", file };
        try CmdCall(alloc, &command);
    }

    pub fn echo(alloc: std.mem.Allocator, arg: []const u8) !void {
        const command = [_][]const u8{ "echo", arg };
        try CmdCall(alloc, &command);
    }

    pub fn pwd(alloc: std.mem.Allocator) ![]const u8 {
        const command = [_][]const u8{"pwd"};
        return CmdCallAndReturn(alloc, &command);
    }
};

pub const package = struct {
    pub const apt = struct {
        pub fn install(alloc: std.mem.Allocator, pkg: []const u8, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "apt", "install", "-y", pkg };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "apt", "install", pkg };
                try CmdCall(alloc, &command);
            }
        }

        pub fn remove(alloc: std.mem.Allocator, pkg: []const u8, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "apt", "remove", "-y", pkg };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "apt", "remove", pkg };
                try CmdCall(alloc, &command);
            }
        }
        pub fn update(alloc: std.mem.Allocator, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "apt", "update", "-y" };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "apt", "update" };
                try CmdCall(alloc, &command);
            }
        }
    };

    pub const dnf = struct {
        pub fn install(alloc: std.mem.Allocator, pkg: []const u8, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "dnf", "install", "-y", pkg };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "dnf", "install", pkg };
                try CmdCall(alloc, &command);
            }
        }

        pub fn remove(alloc: std.mem.Allocator, pkg: []const u8, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "dnf", "remove", "-y", pkg };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "dnf", "remove", pkg };
                try CmdCall(alloc, &command);
            }
        }

        pub fn update(alloc: std.mem.Allocator, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "dnf", "update", "-y" };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "dnf", "update" };
                try CmdCall(alloc, &command);
            }
        }
    };

    pub const pacman = struct {
        pub fn install(alloc: std.mem.Allocator, pkg: []const u8, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "pacman", "-S", "-noconfirm", pkg };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "pacman", "-S", pkg };
                try CmdCall(alloc, &command);
            }
        }

        pub fn remove(alloc: std.mem.Allocator, pkg: []const u8, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "pacman", "-R", "-noconfirm", pkg };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "pacman", "-R", pkg };
                try CmdCall(alloc, &command);
            }
        }

        pub fn update(alloc: std.mem.Allocator, auto_yes: bool) !void {
            if (auto_yes) {
                const command = [_][]const u8{ "sudo", "pacman", "-Syu", "-noconfirm" };
                try CmdCall(alloc, &command);
            } else {
                const command = [_][]const u8{ "sudo", "pacman", "-Syu" };
                try CmdCall(alloc, &command);
            }
        }
    };
};

pub const user = struct {
    pub fn get_uid() !u32 {
        const UID = std.os.linux.getuid();
        return UID;
    }

    pub fn get_name(alloc: std.mem.Allocator) ![]const u8 {
        const command = [_][]const u8{"whoami"};
        return CmdCallAndReturn(alloc, &command);
    }
};
