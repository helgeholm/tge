const std = @import("std");
const singleton = @import("singleton.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    var t = try singleton.init(gpa.allocator(), .{ .width = 100, .height = 40 });
    defer t.deinit();

    try t.run();
}
