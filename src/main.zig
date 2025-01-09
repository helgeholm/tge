const std = @import("std");
const tge = @import("tge.zig");

var t: tge.Tge = undefined;

fn win_resize_handler(_: c_int) callconv(.C) void {
    t.win_resized();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    t = tge.Tge{ .allocator = alloc, .display = .{ .width = 100, .height = 40 } };
    defer t.deinit();
    const act = std.posix.Sigaction{
        .handler = .{ .handler = win_resize_handler },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    std.posix.sigaction(std.posix.SIG.WINCH, &act, null);
    try t.run();
    std.debug.print("All your {} are belong to us.\n", .{t});
}
