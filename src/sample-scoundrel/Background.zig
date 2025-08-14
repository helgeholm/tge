const std = @import("std");

const tge = @import("tge");
const Display = tge.Display;
const MainBus = @import("MainBus.zig");

bus: MainBus,
messageSlice: [10][]const u8 = .{ "", "", "", "", "", "", "", "", "", "" },
messageNewTTL: usize = 0,
board: tge.Image = .{ .source = @import("images/board.zon") },

pub fn init(self: *@This()) void {
    self.board.init(self.bus.alloc);
}

pub fn deinit(self: *@This()) void {
    self.board.deinit(self.bus.alloc);
}

pub fn message(self: *@This(), fmted: []const u8) void {
    if (fmted.len > "You replace your weapon (6)".len)
        @panic(fmted);
    for (0..9) |i| {
        self.messageSlice[i] = self.messageSlice[i + 1];
    }
    self.messageSlice[9] = fmted;
    self.messageNewTTL = 59;
}

pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.messageNewTTL > 0)
        self.messageNewTTL -= 1;
}

pub fn draw(ptr: *anyopaque, display: *Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    display.putImage(&self.board, 0, 0);
    const msgTop: isize = 20;
    const msgLeft: isize = 26;
    for (0..9) |ui| {
        const i: isize = @intCast(ui);
        display.text(msgLeft, msgTop + i, self.messageSlice[ui], .white);
    }
    if (@mod(self.messageNewTTL, 20) < 15)
        display.text(msgLeft, msgTop + 9, self.messageSlice[9], .hi_white);
}
