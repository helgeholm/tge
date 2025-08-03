const std = @import("std");
const tge = @import("tge");

const help = tge.Sprite{ .data = @embedFile("sprites/help"), .width = 87 };
const win = tge.Sprite{ .data = @embedFile("sprites/win"), .width = 24 };
const dead = tge.Sprite{ .data = @embedFile("sprites/dead"), .width = 24 };

isHelping: bool = false,
isWinning: bool = false,
isLosing: bool = false,
random: std.Random,
shadeSeed: u64 = 0,
shadeTick: u16 = 0,

pub fn paused(self: *@This()) bool {
    return self.isHelping or self.isWinning or self.isLosing;
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
                    display.put(@intCast(x), @intCast(y), ' ');
            }
        };
    if (self.isHelping)
        display.blot(&help, 7, 2);
    if (self.isWinning)
        display.blot(&win, 39, 20);
    if (self.isLosing)
        display.blot(&dead, 39, 20);
}
