const std = @import("std");
const tge = @import("tge");

const help = tge.Sprite{ .data = @embedFile("sprites/help"), .width = 87 };

isHelping: bool = false,
random: std.Random,
shadeSeed: u64 = 0,
shadeTick: u16 = 0,

pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.shadeTick == 0) {
        self.shadeTick = 30;
        self.shadeSeed = self.random.int(u64);
    }
    self.shadeTick -= 1;
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    var rng = std.Random.Pcg.init(self.shadeSeed);
    const r = rng.random();
    if (self.isHelping) {
        for (0..@intCast(display.height)) |y| {
            for (0..@intCast(display.width)) |x| {
                if (r.intRangeLessThan(u8, 0, 4) > 0)
                    display.put(@intCast(x), @intCast(y), ' ');
            }
        }
        display.blot(&help, 7, 2);
    }
}
