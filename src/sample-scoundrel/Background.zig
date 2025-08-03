const std = @import("std");

const tge = @import("tge");
const Display = tge.Display;

messageBuf: [1024]u8 = undefined,
messageBufP: usize = 0,
messageSlice: [11][]const u8 = .{ "", "", "", "", "", "", "", "", "", "", "" },
messageNewTTL: usize = 0,
board: tge.Image = .{ .source = @import("images/board.zon") },

pub fn init(self: *@This(), alloc: std.mem.Allocator) void {
    self.board.init(alloc);
}

pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
    self.board.deinit(alloc);
}

pub fn message(self: *@This(), comptime fmt: []const u8, args: anytype) void {
    for (0..10) |i| {
        self.messageSlice[i] = self.messageSlice[i + 1];
    }
    const fmted = std.fmt.bufPrint(self.messageBuf[self.messageBufP..], fmt, args) catch unreachable;
    self.messageSlice[10] = fmted;
    self.messageBufP += fmted.len;
    if (self.messageBufP > 900) self.messageBufP = 0;
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
    const msgTop: isize = 28;
    const msgLeft: isize = 46;
    for (0..10) |ui| {
        const i: isize = @intCast(ui);
        display.text(msgLeft, msgTop + i, self.messageSlice[ui]);
    }
    if (@mod(self.messageNewTTL, 20) < 15)
        display.text(msgLeft, msgTop + 10, self.messageSlice[10]);
}
