const std = @import("std");
const tge = @import("tge");

const Card = @import("Card.zig");
const MainBus = @import("MainBus.zig");

const top: isize = 0;
const left: isize = 0;
const height: isize = 18;
const width: isize = 100;

const DiscardedCard = struct {
    card: *Card,
    x: isize,
    y: isize,
    pub fn init(random: std.Random, card: *Card, w: isize, h: isize) DiscardedCard {
        return .{
            .card = card,
            .x = random.intRangeLessThan(isize, left, w - card.image.width),
            .y = random.intRangeLessThan(isize, top, h - card.image.height),
        };
    }
    pub fn draw(self: DiscardedCard, display: *tge.Display) void {
        self.card.drawDead(self.x, self.y, display);
    }
};

bus: MainBus,
cards: std.ArrayList(DiscardedCard) = undefined,

pub fn discard(self: *@This(), card: *Card) void {
    const new = self.cards.addOne() catch unreachable;
    new.* = DiscardedCard.init(self.bus.rng, card, width, height);
}

pub fn init(self: *@This()) void {
    self.cards = std.ArrayList(DiscardedCard).init(self.bus.alloc);
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
