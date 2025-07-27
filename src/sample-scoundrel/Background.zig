const std = @import("std");

const tge = @import("tge");
const Display = tge.Display;

messageBuf: [60]u8 = undefined,
messageSlice: []const u8 = "",
messageTTL: u16 = 0,

const board = tge.Sprite{ .data = @embedFile("sprites/board"), .width = 101 };

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
    display.blot(&board, 0, 0);
    const msgBlink = (self.messageTTL > 0 and @mod(self.messageTTL, 30) >= 20);
    if (msgBlink) {
        for (3..@intCast(display.width - 3)) |ux| {
            const x: isize = @intCast(ux);
            display.put(x, 2, '-');
            display.put(x, 4, '-');
        }
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
