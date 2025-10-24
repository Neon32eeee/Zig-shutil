const std = @import("std");
const Core = @import("Core.zig");
const CmdCall = Core.CmdCall;
const CmdCallAndReturn = Core.CmdCallAndReturn;
const CmdSettings = Core.CmdSettings;
const ShutilError = Core.ShutilError;

// ------------------------
// Namespace for git utils |
// ------------------------
pub const git = struct {
    // clones the poject from url
    pub fn clone(settings: CmdSettings, url: []const u8) !void {
        const command = [_][]const u8{ "git", "clone", url };
        try CmdCall(settings, &command);
    }

    // the commits poject with commentary
    pub fn commit(settings: CmdSettings, comment: []const u8) !void {
        const command = [_][]const u8{ "git", "commit", "-m", comment };
        try CmdCall(settings, &command);
    }

    // the push with source branch ih target branch
    pub fn push(settings: CmdSettings, source_branch: []const u8, target_branch: []const u8) !void {
        const command = [_][]const u8{ "git", "push", source_branch, target_branch };
        try CmdCall(settings, &command);
    }

    // the adds file in commit
    pub fn add(settings: CmdSettings, file: []const u8) !void {
        const command = [_][]const u8{ "git", "add", file };
        try CmdCall(settings, &command);
    }

    // the pull in source branch with target branch
    pub fn pull(settings: CmdSettings, source_branch: []const u8, target_branch: []const u8) !void {
        const command = [_][]const u8{ "git", "pull", source_branch, target_branch };
        try CmdCall(settings, &command);
    }
};
