const std = @import("std");
const Core = @import("../Core.zig");
const CmdCall = Core.CmdCall;
const CmdCallAndReturn = Core.CmdCallAndReturn;
const CmdSettings = Core.CmdSettings;
const ShutilError = Core.ShutilError;

// -------------------------------------------
// Namespace for package management utilities |
// -------------------------------------------
pub const package = struct {
    //-----------------------------------
    // Namespace for apt package manager |
    // ----------------------------------
    pub const apt = struct {
        // Installs a package using apt
        pub fn install(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "apt", "install", args.items, pkg };
            try CmdCall(settings, &command);
        }

        // Removes a package using apt
        pub fn remove(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "apt", "remove", args.items, pkg };
            try CmdCall(settings, &command);
        }

        // Updates the apt package index
        pub fn update(settings: CmdSettings, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "apt", "update", args.items };
            try CmdCall(settings, &command);
        }

        // Checks if apt is available
        pub fn isAvailable(
            settings: CmdSettings,
        ) !bool {
            const command = [_][]const u8{ "command", "-v", "apt" };
            const result = CmdCallAndReturn(settings, &command) catch {
                return false;
            };
            defer settings.allocator.free(result);
            return result.len > 0;
        }
    };

    // ----------------------------------
    // Namespace for dnf package manager |
    // ----------------------------------
    pub const dnf = struct {
        // Installs a package using dnf
        pub fn install(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "dnf", "install", args.items, pkg };
            try CmdCall(settings, &command);
        }

        // Removes a package using dnf
        pub fn remove(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "dnf", "remove", args.items, pkg };
            try CmdCall(settings, &command);
        }

        // Updates the dnf package index
        pub fn update(settings: CmdSettings, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "dnf", "update", args.items };
            try CmdCall(settings, &command);
        }

        // Checks if dnf is available
        pub fn isAvailable(
            settings: CmdSettings,
        ) !bool {
            const command = [_][]const u8{ "command", "-v", "dnf" };
            const result = CmdCallAndReturn(settings, &command) catch {
                return false;
            };
            defer settings.allocator.free(result);
            return result.len > 0;
        }
    };

    // -------------------------------------
    // Namespace for pacman package manager |
    // -------------------------------------
    pub const pacman = struct {
        // Installs a package using pacman
        pub fn install(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-noconfirm");

            const command = [_][]const u8{ "sudo", "pacman", "-S", pkg };
            try CmdCall(settings, &command);
        }

        // Removes a package using pacman
        pub fn remove(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-noconfirm");

            const command = [_][]const u8{ "sudo", "pacman", "-R", pkg };
            try CmdCall(settings, &command);
        }

        // Updates the pacman package index
        pub fn update(settings: CmdSettings, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-noconfirm");

            const command = [_][]const u8{ "sudo", "pacman", "-Syu" };
            try CmdCall(settings, &command);
        }

        // Checks if pacman is available
        pub fn isAvailable(
            settings: CmdSettings,
        ) !bool {
            const command = [_][]const u8{ "command", "-v", "pacman" };
            const result = CmdCallAndReturn(settings, &command) catch {
                return false;
            };
            defer settings.allocator.free(result);
            return result.len > 0;
        }
    };

    // ----------------------------------
    // Namespace for yum package manager |
    // ----------------------------------
    pub const yum = struct {
        // Installs a package using yumcomptime fmt: []const u8
        pub fn install(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "yum", "install", args.items, pkg };
            try CmdCall(settings, &command);
        }

        // Removes a package using yum
        pub fn remove(settings: CmdSettings, pkg: []const u8, flags: struct { auto_yes: bool = false }) !void {
            if (pkg.len == 0) return ShutilError.InvalidArg;

            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "yum", "remove", args.items, pkg };
            try CmdCall(settings, &command);
        }

        // Updates the yum package index
        pub fn update(settings: CmdSettings, flags: struct { auto_yes: bool = false }) !void {
            var args = std.ArrayList(u8).init(settings.allocator);

            if (flags.auto_yes) try args.appendSlice("-y");

            const command = [_][]const u8{ "sudo", "yum", "update", args.items };
            try CmdCall(settings, &command);
        }

        // Checks if yum is available
        pub fn isAvailable(
            settings: CmdSettings,
        ) !bool {
            const command = [_][]const u8{ "command", "-v", "yum" };
            const result = CmdCallAndReturn(settings, &command) catch {
                return false;
            };
            defer settings.allocator.free(result);
            return result.len > 0;
        }
    };
};
