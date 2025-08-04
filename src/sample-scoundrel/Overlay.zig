const std = @import("std");
const tge = @import("tge");

isHelping: bool = false,
isWinning: bool = false,
isLosing: bool = false,
random: std.Random,
shadeSeed: u64 = 0,
shadeTick: u16 = 0,
help: tge.Image = .{ .source = @import("images/help.zon") },
win: tge.Image = .{ .source = @import("images/win.zon") },
dead: tge.Image = .{ .source = @import("images/dead.zon") },

pub fn paused(self: *@This()) bool {
    return self.isHelping or self.isWinning or self.isLosing;
}

pub fn init(self: *@This(), alloc: std.mem.Allocator) void {
    self.help.init(alloc);
    self.win.init(alloc);
    self.dead.init(alloc);
}

pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
    self.help.deinit(alloc);
    self.win.deinit(alloc);
    self.dead.deinit(alloc);
}

pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.shadeTick == 0) {
        self.shadeTick = 20;
        self.shadeSeed = self.random.int(u64);
    }
    self.shadeTick -= 1;
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    var rng = std.Random.Pcg.init(self.shadeSeed);
    const r = rng.random();
    if (self.paused())
        for (0..@intCast(display.height)) |y| {
            for (0..@intCast(display.width)) |x| {
                if (r.intRangeLessThan(u8, 0, 4) == 0)
                    display.put(@intCast(x), @intCast(y), ' ', .white);
            }
        };
    if (self.isHelping)
        display.putImage(&self.help, 7, 2);
    if (self.isWinning)
        display.putImage(&self.win, 39, 19);
    if (self.isLosing)
        display.putImage(&self.dead, 40, 18);
}
