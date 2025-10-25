const std = @import("std");
const Core = @import("../Core.zig");
const CmdCall = Core.CmdCall;
const CmdCallAndReturn = Core.CmdCallAndReturn;
const CmdSettings = Core.CmdSettings;
const ShutilError = Core.ShutilError;

// ---------------------
// Namespace path utils |
// ---------------------
pub const path = struct {
    // Returh real path
    pub fn realpath(settings: CmdSettings, source_path: []const u8) ![]const u8 {
        const command = [_][]const u8{ "realpath", source_path };
        return try CmdCallAndReturn(settings, &command);
    }

    // Return file name without a path
    pub fn basename(settings: CmdSettings, source_path: []const u8) ![]const u8 {
        const command = [_][]const u8{ "basename", source_path };
        return try CmdCallAndReturn(settings, &command);
    }

    // Returh path to file
    pub fn dirname(settings: CmdSettings, source_path: []const u8) ![]const u8 {
        const command = [_][]const u8{ "dirname", source_path };
        return try CmdCallAndReturn(settings, &command);
    }

    pub fn cd(settings: CmdSettings, target_path: []const u8) ![]const u8 {
        const command = [_][]const u8{ "cd", target_path };
        try CmdCall(settings, &command);
    }

    // Checking for path existence
    pub fn exists(settings: CmdSettings, target_path: []const u8) !bool {
        const command = [_][]const u8{ "test", "-e", target_path };
        CmdCall(settings, &command) catch |err| {
            if (err == ShutilError.ProcessFailed) return false;
            return err;
        };
        return true;
    }
};
