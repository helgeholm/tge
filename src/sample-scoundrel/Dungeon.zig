const std = @import("std");
const tge = @import("tge");

const Card = @import("Card.zig");
const MainBus = @import("MainBus.zig");

const top: isize = 14;
const left: isize = 6;

bus: MainBus,
pile: std.ArrayList(*Card) = undefined,
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
    display.put(3, 22, txt[0], .hi_white);
    display.put(3, 23, txt[1], .hi_white);
}

pub fn init(self: *@This()) void {
    self.imgFull.init(self.bus.alloc);
    self.imgMedium.init(self.bus.alloc);
    self.imgSmall.init(self.bus.alloc);
    self.pile = std.ArrayList(*Card).init(self.bus.alloc);
}

pub fn reset(self: *@This()) void {
    self.pile.clearRetainingCapacity();
    const cards = self.bus.getCards();
    for (cards) |*c| {
        const added = self.pile.addOne() catch unreachable;
        added.* = c;
    }
    self.bus.rng.shuffle(*Card, self.pile.items);
}

pub fn deinit(self: *@This()) void {
    self.imgFull.deinit(self.bus.alloc);
    self.imgMedium.deinit(self.bus.alloc);
    self.imgSmall.deinit(self.bus.alloc);
    self.pile.deinit();
}
