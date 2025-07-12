const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");
const Dungeon = @import("Dungeon.zig");

dungeon: *Dungeon,
cards: [4]?*Deck.Card = .{ null, null, null, null },

pub fn pull(self: *@This()) void {
    for (0..4) |i| {
        self.cards[i] = self.dungeon.pile.pop().?;
    }
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    for (0..4) |i| {
        if (self.cards[i]) |c| {
            display.blot(&c.sprite, 38 + @as(i16, @intCast(i)) * 10, 15);
        }
    }
}
