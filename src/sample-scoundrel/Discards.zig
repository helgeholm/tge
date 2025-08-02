const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");

const top: isize = 0;
const left: isize = 0;
const height: isize = 16;
const width: isize = 100;

const DiscardedCard = struct {
    card: Deck.Card,
    x: isize,
    y: isize,
    pub fn init(random: std.Random, card: Deck.Card, w: isize, h: isize) DiscardedCard {
        return .{
            .card = card,
            .x = random.intRangeLessThan(isize, left, w - card.sprite.width),
            .y = random.intRangeLessThan(isize, top, h - card.sprite.height()),
        };
    }
    pub fn draw(self: DiscardedCard, display: *tge.Display) void {
        self.card.drawDead(self.x, self.y, display);
    }
};

random: std.Random,
cards: std.ArrayList(DiscardedCard) = undefined,
allocator: std.mem.Allocator,

pub fn discard(self: *@This(), card: Deck.Card) void {
    const new = self.cards.addOne() catch unreachable;
    new.* = DiscardedCard.init(self.random, card, width, height);
}

pub fn init(self: *@This()) void {
    self.cards = std.ArrayList(DiscardedCard).init(self.allocator);
}

pub fn deinit(self: *@This()) void {
    self.cards.deinit();
}

pub fn reset(self: *@This()) void {
    self.cards.clearRetainingCapacity();
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    for (self.cards.items) |c| {
        c.draw(display);
    }
}
