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
    pub fn curl(setting: CmdSettings, url: []const u8) ![]const u8 {
        const command = [_][]const u8{ "curl", url };
        const result = try CmdCallAndReturn(setting, &command);

        if (result.len == 0) {
            return "";
        }

        return result;
    }
};
