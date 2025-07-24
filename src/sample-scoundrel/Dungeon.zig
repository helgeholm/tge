const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");

const imgFull: []const u8 = @embedFile("sprites/deck_full");
const imgMedium: []const u8 = @embedFile("sprites/deck_medium");
const imgSmall: []const u8 = @embedFile("sprites/deck_small");

const top: isize = 8;
const left: isize = 10;

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
    const txt = std.fmt.bufPrint(&buf, "{d}", .{self.pile.items.len}) catch undefined;
    display.text(left + 13, top + 9, txt);
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
