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
    pub fn curl(settings: CmdSettings, url: []const u8) ![]const u8 {
        const command = [_][]const u8{ "curl", url };
        const result = try CmdCallAndReturn(settings, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }

    pub fn wget(settings: CmdSettings, url: []const u8) !void {
        const command = [_][]const u8{ "wget", url };
        try CmdCall(settings, &command);
    }
};
