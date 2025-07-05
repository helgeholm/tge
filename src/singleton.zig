const std = @import("std");
const Tge = @import("Tge.zig");
const Config = @import("Config.zig");

var t: Tge = undefined;

pub fn init(allocator: std.mem.Allocator, params: Config) !Tge {
    t = try Tge.init(allocator, params);

    const winch_action = std.posix.Sigaction{
        .handler = .{ .handler = win_resize_handler },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.WINCH, &winch_action, null);

    const int_action = std.posix.Sigaction{
        .handler = .{ .handler = exit_handler },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.INT, &int_action, null);

    return t;
}

fn win_resize_handler(_: c_int) callconv(.C) void {
    t.win_resized();
}

fn exit_handler(_: c_int) callconv(.C) void {
    t.deinit();
    std.process.exit(1);
}
