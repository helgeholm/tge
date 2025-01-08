const std = @import("std");

pub const Tge = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,
    ticks: usize = 0,
    pub fn deinit(self: *Tge) void {
        std.debug.print("i am self {d}", .{self.width});
    }
    pub fn run(self: *Tge) !void {
        const FPS60: u64 = 16_666_667;
        var t = std.time.Instant.now() catch unreachable;
        var acc: u64 = 0;
        while (true) {
            const now = std.time.Instant.now() catch unreachable;
            const delta: u64 = if (now.order(t) == .gt) now.since(t) else 0;
            t = now;
            acc = @min(delta + acc, FPS60 * 2);
            while (acc > FPS60) {
                acc -= FPS60;
                self.tick();
            }
            self.draw();
            std.Thread.sleep(FPS60 - acc);
        }
    }
    fn tick(self: *Tge) void {
        self.ticks += 1;
    }
    fn draw(self: *Tge) void {
        const now = std.time.Instant.now() catch unreachable;
        if (@mod(self.ticks, 60) == 0)
            std.debug.print("{d},{d}.{d}\n", .{ self.ticks, now.timestamp.sec, now.timestamp.nsec });
    }
};
