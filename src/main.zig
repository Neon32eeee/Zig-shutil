const std = @import("std");

// Defining custom error types for the library
const ShutilError = error{ ProcessFailed, InvalidPath, NoStdout, CommandNotFound, UserNotFound, InvalidArg };

// Executes a shell command and streams its output to stdout/stderr
fn CmdCall(allocator: std.mem.Allocator, command: []const []const u8) !void {
    // Check if the command is empty
    if (command.len == 0) return ShutilError.CommandNotFound;

    // Initialize a child process with the given command and allocator
    var child = std.process.Child.init(command, allocator);

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
    var buffer: [4096]u8 = undefined;

    // Get standard output and error writers
    const stdout_writer = std.io.getStdOut().writer();
    const stderr_writer = std.io.getStdErr().writer();

    // Read and write stdout to the console
    if (child.stdout) |pipe| {
        while (true) {
            const bytes_read = try pipe.read(&buffer);
            if (bytes_read == 0) break; // Конец потока
            try stdout_writer.writeAll(buffer[0..bytes_read]);
        }
    } else {
        return ShutilError.NoStdout;
    }

    // Read and write stdout to the console
    if (child.stderr) |pipe| {
        while (true) {
            const bytes_read = try pipe.read(&buffer);
            if (bytes_read == 0) break;
            try stderr_writer.writeAll(buffer[0..bytes_read]);
        }
    }

    // Wait for the process to complete and check its exit status
    const term = try child.wait();
    if (term.Exited != 0) {
        std.debug.print("Command: {s}\n", .{command});
        return ShutilError.ProcessFailed;
    }
}

// Executes a shell command and returns its stdout as a string
fn CmdCallAndReturn(allocator: std.mem.Allocator, command: []const []const u8) ![]const u8 {
    // Initialize a child process with the given command and allocator
    var child = std.process.Child.init(command, allocator);

    // Configure the child process to pipe stdout and stderr
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    // Spawn the child process
    try child.spawn();

    // Ensure pipes are closed after function execution
    defer if (child.stdout) |*pipe| pipe.close();
    defer if (child.stderr) |*pipe| pipe.yumclose();

    // Read the entire stdout into a buffer
    const stdout = if (child.stdout) |pipe| try pipe.readToEndAlloc(allocator, 1024 * 1024) else return ShutilError.NoStdout;

    // Read the entire stderr into a buffer
    const stderr = if (child.stderr) |pipe| try pipe.readToEndAlloc(allocator, 1024 * 1024) else &[_]u8{};
    defer allocator.free(stderr);
    if (stderr.len > 0) {
        std.debug.print("Error: {s}\n", .{stderr});
        defer allocator.free(stderr);
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
        allocator.free(stdout);
        return ShutilError.UserNotFound;
    }

    // Duplicate the trimmed output for return
    const result = try allocator.dupe(u8, trimmed);
    allocator.free(stdout);
    return result;
}

// Namespace for command-related utilities
pub const cmd = struct {
    // Checks if a command is available in the system
    pub fn isAvailableCommand(allocator: std.mem.Allocator, command: []const u8) !bool {
        const CommandTrimmed = [_][]const u8{ "command", "-v", command };
        const result = CmdCallAndReturn(allocator, &CommandTrimmed) catch {
            return false;
        };
        defer allocator.free(result);
        return result.len > 0;
    }

    // Namespace for sudo-related commands
    pub const sudo = struct {
        // Runs a command with sudo privileges
        pub fn run(allocator: std.mem.Allocator, command: []const u8) !void {
            const CommandTrimmed = [_][]const u8{ "sudo", "sh", "-c", command };
            try CmdCall(allocator, &CommandTrimmed);
        }
    };

    // Runs a shell command
    pub fn run(allocator: std.mem.Allocator, command: []const u8) !void {
        const CommandTrimmed = [_][]const u8{ "sh", "-c", command };
        try CmdCall(allocator, &CommandTrimmed);
    }

    // Moves a file or directory
    pub fn mv(allocator: std.mem.Allocator, source: []const u8, target: []const u8, flags: struct { force: bool = false }) !void {
        if (source.len == 0 or target.len == 0) return ShutilError.InvalidPath;
        std.fs.cwd().access(source, .{}) catch return ShutilError.varInvalidPath;

        var args = std.ArrayList(u8).init(allocator);
        defer args.deinit();

        if (flags.force) args.appendSlice("-f");

        if (args.items.len != 0) {
            const command = [_][]const u8{ "mv", args.items, source, target };
            try CmdCall(allocator, &command);
        } else {
            const command = [_][]const u8{ "mv", source, target };
            try CmdCall(allocator, &command);
        }
    }

    // Creates a directory
    pub fn mkdir(allocator: std.mem.Allocator, name: []const u8, flags: struct { parents: bool = false }) !void {
        var args = std.ArrayList(u8).init(allocator);

        if (flags.parents) try args.appendSlice("-p");

        if (args.items.len != 0) {
            const command = [_][]const u8{ "mkdir", args.items, name };
            try CmdCall(allocator, &command);
        } else {
            const command = [_][]const u8{ "mkdir", name };
            try CmdCall(allocator, &command);
        }
    }

    // Creates an empty file
    pub fn touch(allocator: std.mem.Allocator, name: []const u8) !void {
        const command = [_][]const u8{ "touch", name };
        try CmdCall(allocator, &command);
    }

    // Displays the contents of a file
    pub fn cat(allocator: std.mem.Allocator, file: []const u8) !void {
        if (file.len == 0) return ShutilError.InvalidPath;
        std.fs.cwd().access(file, .{}) catch return ShutilError.InvalidPath;
        const command = [_][]const u8{ "cat", file };
        try CmdCall(allocator, &command);
    }

    // Prints a string to stdout
    pub fn echo(allocator: std.mem.Allocator, arg: []const u8) !void {
        const command = [_][]const u8{ "echo", arg };
        try CmdCall(allocator, &command);
    }

    // Returns the current working directory
    pub fn pwd(allocator: std.mem.Allocator) ![]const u8 {
        const command = [_][]const u8{"pwd"};
        return CmdCallAndReturn(allocator, &command);
    }

    // Removes a file or directory
    pub fn rm(allocator: std.mem.Allocator, file: []const u8, flags: struct { dir: bool = false, force: bool = false, verbose: bool = false }) !void {
        if (file.len == 0) return ShutilError.InvalidArg;
        var args = std.ArrayList(u8).init(allocator);
        defer args.deinit();

        if (flags.dir) try args.appendSlice("-r");
        if (flags.force) try args.appendSlice("-f");
        if (flags.verbose) try args.appendSlice("-v");

        const command = [_][]const u8{ "rm", args.items, file };
        try CmdCall(allocator, &command);
    }

    // Searches for files matching a pattern
    pub fn find(allocator: std.mem.Allocator, pattern: []const u8, flags: struct { type: ?enum { file, dir } = null }) ![]const u8 {
        if (pattern.len == 0) return ShutilError.InvalidArg;

        var args = std.ArrayList(u8).init(allocator);
        defer args.deinit();

        if (flags.type) |t| {
            try args.appendSlice("-type");
            try args.appendSlice(if (t == .file) " f" else " d");
        }

        const command = [_][]const u8{
            "sh",
            "-c",
            "find",
            pattern,
            args.items,
        };
        const result = try CmdCallAndReturn(allocator, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }

    // Searches for a pattern in a file
    pub fn grep(allocator: std.mem.Allocator, pattern: []const u8, file: []const u8) ![]const u8 {
        if (pattern.len == 0) return ShutilError.InvalidArg;
        const command = [_][]const u8{ "grep", pattern, file };
        const result = try CmdCallAndReturn(allocator, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }
};

// Namespace for package management utilities
pub const package = struct {
    // Namespace for apt package manager
    pub const apt = struct {
        // Installs a package using apt
        pub fn install(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "apt", "install", args.items, pkg };
            try CmdCall(allocator, &command);
        }

        // Removes a package using apt
        pub fn remove(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "apt", "remove", args.items, pkg };
            try CmdCall(allocator, &command);
        }

        // Updates the apt package index
        pub fn update(allocator: std.mem.Allocator, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "apt", "update", args.items };
            try CmdCall(allocator, &command);
        }

        // Checks if apt is available
        pub fn isAvailable(allocator: std.mem.Allocator) !bool {
            const command = [_][]const u8{ "command", "-v", "apt" };
            const result = CmdCallAndReturn(allocator, &command) catch {
                return false;
            };
            defer allocator.free(result);
            return result.len > 0;
        }
    };

    // Namespace for dnf package manager
    pub const dnf = struct {
        // Installs a package using dnf
        pub fn install(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "dnf", "install", args.items, pkg };
            try CmdCall(allocator, &command);
        }

        // Removes a package using dnf
        pub fn remove(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "dnf", "remove", args.items, pkg };
            try CmdCall(allocator, &command);
        }

        // Updates the dnf package index
        pub fn update(allocator: std.mem.Allocator, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "dnf", "update", args.items };
            try CmdCall(allocator, &command);
        }

        // Checks if dnf is available
        pub fn isAvailable(allocator: std.mem.Allocator) !bool {
            const command = [_][]const u8{ "command", "-v", "dnf" };
            const result = CmdCallAndReturn(allocator, &command) catch {
                return false;
            };
            defer allocator.free(result);
            return result.len > 0;
        }
    };

    // Namespace for pacman package manager
    pub const pacman = struct {
        // Installs a package using pacman
        pub fn install(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-noconfirm");

            const command = [_][]const u8{ "sudo", "pacman", "-S", pkg };
            try CmdCall(allocator, &command);
        }

        // Removes a package using pacman
        pub fn remove(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-noconfirm");

            const command = [_][]const u8{ "sudo", "pacman", "-R", pkg };
            try CmdCall(allocator, &command);
        }

        // Updates the pacman package index
        pub fn update(allocator: std.mem.Allocator, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-noconfirm");

            const command = [_][]const u8{ "sudo", "pacman", "-Syu" };
            try CmdCall(allocator, &command);
        }

        // Checks if pacman is available
        pub fn isAvailable(allocator: std.mem.Allocator) !bool {
            const command = [_][]const u8{ "command", "-v", "pacman" };
            const result = CmdCallAndReturn(allocator, &command) catch {
                return false;
            };
            defer allocator.free(result);
            return result.len > 0;
        }
    };

    // Namespace for yum package manager
    pub const yum = struct {
        // Installs a package using yum
        pub fn install(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "yum", "install", args.items, pkg };
            try CmdCall(allocator, &command);
        }

        // Removes a package using yum
        pub fn remove(allocator: std.mem.Allocator, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "yum", "remove", args.items, pkg };
            try CmdCall(allocator, &command);
        }

        // Updates the yum package index
        pub fn update(allocator: std.mem.Allocator, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "yum", "update", args.items };
            try CmdCall(allocator, &command);
        }

        // Checks if yum is available
        pub fn isAvailable(allocator: std.mem.Allocator) !bool {
            const command = [_][]const u8{ "command", "-v", "yum" };
            const result = CmdCallAndReturn(allocator, &command) catch {
                return false;
            };
            defer allocator.free(result);
            return result.len > 0;
        }
    };
};

// Namespace for user management utilities
pub const user = struct {
    // Retrieves the current user's UID
    pub fn get_uid() !u32 {
        const UID = std.os.linux.getuid();
        return UID;
    }

    // Retrieves the current user's username
    pub fn get_name(allocator: std.mem.Allocator) ![]const u8 {
        const command = [_][]const u8{"whoami"};
        const result = try CmdCallAndReturn(allocator, &command);
        if (result.len == 0) {
            return ShutilError.UserNotFound;
        }
        return result;
    }

    // Adds a new user to the system
    pub fn add_user(allocator: std.mem.Allocator, username: []const u8) !void {
        const command = [_][]const u8{ "sudo", "useradd", username };
        try CmdCall(allocator, &command);
    }

    // Deletes a user from the system
    pub fn del_user(allocator: std.mem.Allocator, username: []const u8) !void {
        const command = [_][]const u8{ "sudo", "userdel", username };
        try CmdCall(allocator, &command);
    }
};

// Namespace for git utils
pub const git = struct {
    // clones the poject from url
    pub fn clone(allocator: std.mem.Allocator, url: []const u8) !void {
        const command = [_][]const u8{ "git", "clone", url };
        try CmdCall(allocator, &command);
    }

    // the commits poject with commentary
    pub fn commit(allocator: std.mem.Allocator, comment: []const u8) !void {
        const command = [_][]const u8{ "git", "commit", "-m", comment };
        try CmdCall(allocator, &command);
    }

    // the push with source branch ih target branch
    pub fn push(allocator: std.mem.Allocator, source_branch: []const u8, target_branch: []const u8) !void {
        const command = [_][]const u8{ "git", "push", source_branch, target_branch };
        try CmdCall(allocator, &command);
    }

    // the adds file in commit
    pub fn add(allocator: std.mem.Allocator, file: []const u8) !void {
        const command = [_][]const u8{ "git", "add", file };
        try CmdCall(allocator, &command);
    }

    // the pull in source branch with target branch
    pub fn pull(allocator: std.mem.Allocator, source_branch: []const u8, target_branch: []const u8) !void {
        const command = [_][]const u8{ "git", "pull", source_branch, target_branch };
        try CmdCall(allocator, &command);
    }
};
