const std = @import("std");
const tge = @import("tge");
const MainBus = @import("MainBus.zig");

bus: MainBus,
isHelping: bool = false,
isWinning: bool = false,
isLosing: bool = false,
shadeSeed: u64 = 0,
shadeTick: u16 = 0,
help: tge.Image = .{ .source = @import("images/help.zon") },
win: tge.Image = .{ .source = @import("images/win.zon") },
dead: tge.Image = .{ .source = @import("images/dead.zon") },

pub fn paused(self: *@This()) bool {
    return self.isHelping or self.isWinning or self.isLosing;
}

pub fn init(self: *@This()) void {
    self.help.init(self.bus.alloc);
    self.win.init(self.bus.alloc);
    self.dead.init(self.bus.alloc);
}

pub fn deinit(self: *@This()) void {
    self.help.deinit(self.bus.alloc);
    self.win.deinit(self.bus.alloc);
    self.dead.deinit(self.bus.alloc);
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (keys['k']) self.isHelping = false;
    if (self.shadeTick == 0) {
        self.shadeTick = 20;
        self.shadeSeed = self.bus.rng.int(u64);
    }
    self.shadeTick -= 1;
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    var rng = std.Random.Pcg.init(self.shadeSeed);
    const r = rng.random();
    if (self.paused()) {
        display.backgroundArea(0, 0, display.width, display.height, .black);
        display.colorArea(0, 0, display.width, display.height, .hi_black);
        for (0..@intCast(display.height)) |y| {
            for (0..@intCast(display.width)) |x| {
                if (r.intRangeLessThan(u8, 0, 4) == 0)
                    display.put(@intCast(x), @intCast(y), ' ', .white);
            }
        }
    }
    if (self.isHelping)
        display.putImage(&self.help, 1, 1);
    if (self.isWinning)
        display.putImage(&self.win, 15, 8);
    if (self.isLosing)
        display.putImage(&self.dead, 15, 8);
}
