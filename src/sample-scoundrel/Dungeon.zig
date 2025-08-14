const std = @import("std");
const tge = @import("tge");

const Card = @import("Card.zig");
const MainBus = @import("MainBus.zig");

const top: isize = 7;
const left: isize = 1;

bus: MainBus,
pile: std.ArrayList(*Card) = undefined,
imgFull: tge.Image = .{ .source = @import("images/deck_full.zon") },
imgMedium: tge.Image = .{ .source = @import("images/deck_medium.zon") },
imgSmall: tge.Image = .{ .source = @import("images/deck_small.zon") },

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    var buf: [15]u8 = undefined;
    const txt = std.fmt.bufPrint(&buf, "{d:2}", .{self.pile.items.len}) catch undefined;
    display.putImage(switch (self.visibleState()) {
        .full => &self.imgFull,
        .medium => &self.imgMedium,
        .small => &self.imgSmall,
    }, left, top);
    display.text(self.shiftXY(left + 7), self.shiftXY(top + 6), txt, .black);
    self.bus.drawHighZCards(display);
}

pub fn bottomX() isize {
    return left + 2;
}

pub fn bottomY() isize {
    return top + 2;
}

pub fn bottomZ() isize {
    return 500;
}

fn visibleState(self: @This()) enum { full, medium, small } {
    if (self.pile.items.len > 30)
        return .full
    else if (self.pile.items.len > 2)
        return .medium
    else
        return .small;
}

fn shiftXY(self: @This(), xy: isize) isize {
    return switch (self.visibleState()) {
        .full => xy,
        .medium => xy + 1,
        .small => xy + 2,
    };
}

pub fn drawFromTop(self: *@This()) ?*Card {
    if (self.pile.pop()) |c| {
        c.x = self.shiftXY(left);
        c.y = self.shiftXY(top);
        c.z = 1000;
        return c;
    }
    return null;
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
