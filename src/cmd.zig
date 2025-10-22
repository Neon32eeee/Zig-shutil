const std = @import("std");
const Core = @import("Core.zig");
const CmdCall = Core.CmdCall;
const CmdCallAndReturn = Core.CmdCallAndReturn;
const CmdSettings = Core.CmdSettings;
const ShutilError = Core.ShutilError;

// ----------------------------------------
// Namespace for command-related utilities |
// ----------------------------------------
pub const cmd = struct {
    // Checks if a command is available in the system
    pub fn isAvailableCommand(settings: CmdSettings, command: []const u8) !bool {
        const CommandTrimmed = [_][]const u8{ "command", "-v", command };
        const result = CmdCallAndReturn(settings, &CommandTrimmed) catch {
            return false;
        };
        defer settings.allocator.free(result);
        return result.len > 0;
    }

    // ------------------------------------
    // Namespace for sudo-related commands |
    // ------------------------------------
    pub const sudo = struct {
        // Runs a command with sudo privileges
        pub fn run(settings: CmdSettings, command: []const u8) !void {
            const CommandTrimmed = [_][]const u8{ "sudo", "sh", "-c", command };

            try CmdCall(settings, &CommandTrimmed);
        }
    };

    // Runs a shell command
    pub fn run(settings: CmdSettings, command: []const u8) !void {
        const CommandTrimmed = [_][]const u8{ "sh", "-c", command };

        try CmdCall(settings, &CommandTrimmed);
    }

    // Copies a file or directory
    // ╰─Flag recursive remove directory
    // ╰─Flag verbose rpint removed file/directory
    pub fn cp(settings: CmdSettings, source: []const u8, target: []const u8, flags: struct { recursive: bool = false, preserve: bool = false, verbose: bool = false }) !void {
        if (source.len == 0 or target.len == 0) return ShutilError.InvalidPath;
        std.fs.cwd().access(source, .{}) catch return ShutilError.InvalidPath;

        var args = std.ArrayList(u8).init(settings.allocator);
        defer args.deinit();

        if (flags.recursive) try args.appendSlice("-r");
        if (flags.preserve) try args.appendSlice("-p");
        if (flags.verbose) try args.appendSlice("-v");

        if (args.items.len != 0) {
            const command = [_][]const u8{ "cp", args.items, source, target };
            try CmdCall(settings, &command);
        } else {
            const command = [_][]const u8{ "cp", source, target };
            try CmdCall(settings, &command);
        }
    }

    // Moves a file or directory
    // ╰─Flag force suppresses errors if the file doesn't exist
    pub fn mv(settings: CmdSettings, source: []const u8, target: []const u8, flags: struct { force: bool = false }) !void {
        if (source.len == 0 or target.len == 0) return ShutilError.InvalidPath;
        std.fs.cwd().access(source, .{}) catch return ShutilError.InvalidPath;

        var args = std.ArrayList(u8).init(settings.allocator);
        defer args.deinit();

        if (flags.force) args.appendSlice("-f");

        if (args.items.len != 0) {
            const command = [_][]const u8{ "mv", args.items, source, target };
            try CmdCall(settings, &command);
        } else {
            const command = [_][]const u8{ "mv", source, target };
            try CmdCall(settings, &command);
        }
    }

    // Creates a directory
    // ╰─Flag parants creates parent directories as needed
    pub fn mkdir(settings: CmdSettings, name: []const u8, flags: struct { parents: bool = false }) !void {
        var args = std.ArrayList(u8).init(settings.allocator);

        if (flags.parents) try args.appendSlice("-p");

        if (args.items.len != 0) {
            const command = [_][]const u8{ "mkdir", args.items, name };
            try CmdCall(settings, &command);
        } else {
            const command = [_][]const u8{ "mkdir", name };
            try CmdCall(settings, &command);
        }
    }

    // Creates an empty file
    pub fn touch(settings: CmdSettings, name: []const u8) !void {
        const command = [_][]const u8{ "touch", name };

        try CmdCall(settings, &command);
    }

    // Displays the contents of a file
    pub fn cat(settings: CmdSettings, file: []const u8) !void {
        if (file.len == 0) return ShutilError.InvalidPath;
        std.fs.cwd().access(file, .{}) catch return ShutilError.InvalidPath;

        const command = [_][]const u8{ "cat", file };
        try CmdCall(settings, &command);
    }

    // Return content file
    pub fn catReturn(settings: CmdSettings, file: []const u8) ![]const u8 {
        const command = [_][]const u8{ "cat", file };
        const result = try CmdCallAndReturn(settings, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }

    // Prints a string to stdout
    pub fn echo(settings: CmdSettings, text: []const u8) !void {
        const command = [_][]const u8{ "echo", text };
        try CmdCall(settings, &command);
    }

    // Returns the current working directory
    pub fn pwd(settings: CmdSettings) ![]const u8 {
        const command = [_][]const u8{"pwd"};
        return CmdCallAndReturn(settings, &command);
    }

    // Removes a file or directory
    // ╰─Flag dir remove directory
    // ╰─Flag force suppresses errors if the file doesn't exist
    // ╰─Flag verbose rpint removed file/directory
    pub fn rm(settings: CmdSettings, file: []const u8, flags: struct { dir: bool = false, force: bool = false, verbose: bool = false }) !void {
        if (file.len == 0) return ShutilError.InvalidArg;
        var args = std.ArrayList(u8).init(settings.allocator);
        defer args.deinit();

        if (flags.dir) try args.appendSlice("-r");
        if (flags.force) try args.appendSlice("-f");
        if (flags.verbose) try args.appendSlice("-v");

        const command = [_][]const u8{ "rm", args.items, file };
        try CmdCall(settings, &command);
    }

    // Searches for files matching a pattern
    // ╰─Flag type f (file) serch only file, d (dir) serch only dir
    // ╰─Flag maxdepth limits search based on value
    pub fn find(settings: CmdSettings, pattern: []const u8, flags: struct { type: ?enum { file, dir } = null, maxdepth: ?u32 = null }) ![]const u8 {
        if (pattern.len == 0) return ShutilError.InvalidArg;

        var args = std.ArrayList(u8).init(settings.allocator);
        defer args.deinit();

        if (flags.type) |t| {
            try args.appendSlice("-type");
            try args.appendSlice(if (t == .file) " f" else " d");
        }
        if (flags.maxdepth) |m| {
            try args.appendSlice("-maxdepth");
            try args.appendSlice(try std.fmt.allocPrint(settings.allocator, "{}", .{m}));
        }

        const command = [_][]const u8{
            "sh",
            "-c",
            "find",
            pattern,
            args.items,
        };
        const result = try CmdCallAndReturn(settings, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }

    // Searches for a pattern in a file
    pub fn grep(settings: CmdSettings, pattern: []const u8, file: []const u8) ![]const u8 {
        if (pattern.len == 0) return ShutilError.InvalidArg;

        const command = [_][]const u8{ "grep", pattern, file };
        const result = try CmdCallAndReturn(settings, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }
};
