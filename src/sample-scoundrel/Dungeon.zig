const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");

deck: *Deck,
allocator: std.mem.Allocator,
pile: std.ArrayList(*Deck.Card) = undefined,
sprite: tge.Sprite = .{ .data = @embedFile("sprites/deck"), .width = 13 },

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    display.blot(&self.sprite, 20, 15);
}

pub fn init(self: *@This(), random: std.Random) void {
    self.pile = std.ArrayList(*Deck.Card).init(self.allocator);
    for (&self.deck.cards) |*c| {
        const added = self.pile.addOne() catch unreachable;
        added.* = c;
    }
    random.shuffle(*Deck.Card, self.pile.items);
}

pub fn deinit(self: *@This()) void {
    self.pile.deinit();
}
