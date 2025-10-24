const std = @import("std");
const Core = @import("../Core.zig");
const CmdCall = Core.CmdCall;
const CmdCallAndReturn = Core.CmdCallAndReturn;
const CmdSettings = Core.CmdSettings;
const ShutilError = Core.ShutilError;

// ----------------------------------------
// Namespace for user management utilities |
//-----------------------------------------
pub const user = struct {
    // Retrieves the current user's UID
    pub fn getUID() !u32 {
        const UID = std.os.linux.getuid();
        return UID;
    }

    // Retrieves the current user's username
    pub fn getName(settings: CmdSettings) ![]const u8 {
        const command = [_][]const u8{"whoami"};
        const result = try CmdCallAndReturn(settings, &command);
        if (result.len == 0) {
            return ShutilError.UserNotFound;
        }
        return result;
    }

    // Adds a new user to the system
    pub fn addUser(settings: CmdSettings, username: []const u8) !void {
        const command = [_][]const u8{ "sudo", "useradd", username };
        try CmdCall(settings, &command);
    }

    // Deletes a user from the system
    pub fn delUser(settings: CmdSettings, username: []const u8) !void {
        const command = [_][]const u8{ "sudo", "userdel", username };
        try CmdCall(settings, &command);
    }

    pub fn getUserInfo(settings: CmdSettings, name: []const u8) !struct { uid: []const u8, home: []const u8, shell: []const u8 } {
        const command = [_][]const u8{ "getent", "passwd", name };
        const result = try CmdCallAndReturn(settings, &command);

        var fields = std.mem.splitAny(u8, result, ":");

        _ = fields.next();
        _ = fields.next();
        _ = fields.next();
        const uid = fields.next() orelse "";
        _ = fields.next();
        const home = fields.next() orelse "";
        const shell = fields.next() orelse "";

        return .{ .uid = uid, .home = home, .shell = shell };
    }
};
