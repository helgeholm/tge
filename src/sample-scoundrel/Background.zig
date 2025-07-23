const std = @import("std");

const tge = @import("tge");
const Display = tge.Display;

messageBuf: [60]u8 = undefined,
messageSlice: []const u8 = "",
messageTTL: u16 = 0,

pub fn message(self: *@This(), comptime fmt: []const u8, args: anytype, duration: u16) void {
    self.messageSlice = std.fmt.bufPrint(&self.messageBuf, fmt, args) catch unreachable;
    self.messageTTL = duration;
}

pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.messageTTL > 0) {
        self.messageTTL -= 1;
        if (self.messageTTL == 2) {
            @memset(self.messageBuf[0..self.messageSlice.len], '_');
        }
        if (self.messageTTL == 0) {
            self.messageSlice = "";
        }
    }
}

pub fn draw(ptr: *anyopaque, display: *Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    const b: isize = display.height - 1;
    const r: isize = display.width - 1;
    const msgBlink = (self.messageTTL > 0 and @mod(self.messageTTL, 30) >= 20);
    for (0..@intCast(display.width)) |ux| {
        const x: isize = @intCast(ux);
        display.put(x, 0, '#');
        display.put(x, 1, '#');
        display.put(x, 5, '#');
        display.put(x, 6, '#');
        display.put(x, b, '#');
    }
    for (2..5) |uy| {
        const y: isize = @intCast(uy);
        display.put(1, y, '#');
        display.put(r - 1, y, '#');
        display.put(2, y, '#');
        display.put(r - 2, y, '#');
    }
    if (msgBlink) {
        for (3..@intCast(display.width - 3)) |ux| {
            const x: isize = @intCast(ux);
            display.put(x, 2, '-');
            display.put(x, 4, '-');
        }
    }
    for (1..@intCast(display.height - 1)) |uy| {
        const y: isize = @intCast(uy);
        display.put(0, y, '#');
        display.put(r, y, '#');
    }
    if (self.messageTTL > 0) {
        if (self.messageTTL > 2)
            display.text(4, 3, self.messageSlice);
        if (self.messageTTL < 4) {
            const y: isize = 5 - self.messageTTL;
            for (3..@intCast(display.width - 3)) |ux| {
                const x: isize = @intCast(ux);
                display.put(x, y, '_');
            }
        }
    }
}
