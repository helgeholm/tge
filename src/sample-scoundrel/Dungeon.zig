const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");

const imgFull: []const u8 = @embedFile("sprites/deck_full");
const imgMedium: []const u8 = @embedFile("sprites/deck_medium");
const imgSmall: []const u8 = @embedFile("sprites/deck_small");

const top: isize = 13;
const left: isize = 6;

random: std.Random,
deck: *Deck,
allocator: std.mem.Allocator,
pile: std.ArrayList(*Deck.Card) = undefined,
sprite: tge.Sprite = .{ .data = imgFull, .width = 14 },

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.pile.items.len > 30) {
        self.sprite.data = imgFull;
    } else if (self.pile.items.len > 2) {
        self.sprite.data = imgMedium;
    } else {
        self.sprite.data = imgSmall;
    }
    if (self.pile.items.len > 0)
        display.blot(&self.sprite, left, top);
    var buf: [15]u8 = undefined;
    const txt = std.fmt.bufPrint(&buf, "{d} ", .{self.pile.items.len}) catch undefined;
    display.put(3, 22, txt[0]);
    display.put(3, 23, txt[1]);
}

pub fn init(self: *@This()) void {
    self.pile = std.ArrayList(*Deck.Card).init(self.allocator);
}

pub fn reset(self: *@This()) void {
    self.pile.clearRetainingCapacity();
    for (&self.deck.cards) |*c| {
        const added = self.pile.addOne() catch unreachable;
        added.* = c;
    }
    self.random.shuffle(*Deck.Card, self.pile.items);
}

pub fn deinit(self: *@This()) void {
    self.pile.deinit();
}
