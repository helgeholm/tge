const std = @import("std");
const tge = @import("tge.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const alloc = gpa.allocator();
    var t = tge.Tge{ .allocator = alloc, .width = 160, .height = 100 };
    defer t.deinit();
    try t.run();
    std.debug.print("All your {} are belong to us.\n", .{t});
}
