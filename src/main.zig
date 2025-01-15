const std = @import("std");
const tge = @import("tge.zig");

var t: tge.Tge = undefined;

fn win_resize_handler(_: c_int) callconv(.C) void {
    t.win_resized();
}

fn exit_handler(_: c_int) callconv(.C) void {
    t.deinit();
    std.process.exit(1);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    t = try tge.Tge.init(alloc, .{ .width = 100, .height = 40 });
    defer t.deinit();
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
    try t.run();
    std.debug.print("All your {} are belong to us.\n", .{t});
}
