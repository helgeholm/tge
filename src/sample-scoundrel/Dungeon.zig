const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");

const top: isize = 13;
const left: isize = 6;

random: std.Random,
deck: *Deck,
allocator: std.mem.Allocator,
pile: std.ArrayList(*Deck.Card) = undefined,
imgFull: tge.Image = .{ .source = @import("images/deck_full.zon") },
imgMedium: tge.Image = .{ .source = @import("images/deck_medium.zon") },
imgSmall: tge.Image = .{ .source = @import("images/deck_small.zon") },

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    const image =
        if (self.pile.items.len > 30)
            self.imgFull
        else if (self.pile.items.len > 2)
            self.imgMedium
        else
            self.imgSmall;
    if (self.pile.items.len > 0)
        display.putImage(&image, left, top);
    var buf: [15]u8 = undefined;
    const txt = std.fmt.bufPrint(&buf, "{d} ", .{self.pile.items.len}) catch undefined;
    display.put(3, 22, txt[0], .strong_white);
    display.put(3, 23, txt[1], .strong_white);
}

pub fn init(self: *@This()) void {
    self.imgFull.init(self.allocator);
    self.imgMedium.init(self.allocator);
    self.imgSmall.init(self.allocator);
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
    self.imgFull.deinit(self.allocator);
    self.imgMedium.deinit(self.allocator);
    self.imgSmall.deinit(self.allocator);
    self.pile.deinit();
}
