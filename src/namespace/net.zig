const std = @import("std");
const Core = @import("../Core.zig");
const CmdCall = Core.CmdCall;
const CmdCallAndReturn = Core.CmdCallAndReturn;
const CmdSettings = Core.CmdSettings;
const ShutilError = Core.ShutilError;

// --------------
// Nameapace net |
//---------------
pub const net = struct {
    // Get info on site
    pub fn curl(settings: CmdSettings, url: []const u8) ![]const u8 {
        const command = [_][]const u8{ "curl", url };
        const result = try CmdCallAndReturn(settings, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }

    // Get file on site
    pub fn wget(settings: CmdSettings, url: []const u8) !void {
        const command = [_][]const u8{ "wget", url };
        try CmdCall(settings, &command);
    }

    // Check ststus site on url
    pub fn ping(settings: CmdSettings, url: []const u8) ![]const u8 {
        const command = [_][]const u8{ "ping", url };
        const result = try CmdCallAndReturn(settings, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }
};
