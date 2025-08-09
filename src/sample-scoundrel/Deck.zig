const std = @import("std");
const tge = @import("tge");
const Card = @import("Card.zig");

const MainBus = @import("MainBus.zig");
pub fn init(self: *@This()) void {
    for (&self.cards) |*c| {
        c.image.init(self.bus.alloc);
    }
}

pub fn deinit(self: *@This()) void {
    for (&self.cards) |*c| {
        c.image.deinit(self.bus.alloc);
    }
}

pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    for (&self.cards) |*c| {
        if (c.anim == 0)
            c.anim = self.bus.rng.intRangeLessThanBiased(u16, 60, 600);
        c.anim -= 1;
    }
}

bus: MainBus,
cards: [44]Card = .{
    .{
        .suit = .club,
        .strength = 2,
        .image = .{ .source = @import("images/club2.zon") },
    },
    .{
        .suit = .club,
        .strength = 3,
        .image = .{ .source = @import("images/club3.zon") },
    },
    .{
        .suit = .club,
        .strength = 4,
        .image = .{ .source = @import("images/club4.zon") },
    },
    .{
        .suit = .club,
        .strength = 5,
        .image = .{ .source = @import("images/club5.zon") },
    },
    .{
        .suit = .club,
        .strength = 6,
        .image = .{ .source = @import("images/club6.zon") },
    },
    .{
        .suit = .club,
        .strength = 7,
        .image = .{ .source = @import("images/club7.zon") },
    },
    .{
        .suit = .club,
        .strength = 8,
        .image = .{ .source = @import("images/club8.zon") },
    },
    .{
        .suit = .club,
        .strength = 9,
        .image = .{ .source = @import("images/club9.zon") },
    },
    .{
        .suit = .club,
        .strength = 10,
        .image = .{ .source = @import("images/club10.zon") },
    },
    .{
        .suit = .club,
        .strength = 11,
        .image = .{ .source = @import("images/club11.zon") },
    },
    .{
        .suit = .club,
        .strength = 12,
        .image = .{ .source = @import("images/club12.zon") },
    },
    .{
        .suit = .club,
        .strength = 13,
        .image = .{ .source = @import("images/club13.zon") },
    },
    .{
        .suit = .club,
        .strength = 14,
        .image = .{ .source = @import("images/club14.zon") },
    },
    .{
        .suit = .spade,
        .strength = 2,
        .image = .{ .source = @import("images/spade2.zon") },
    },
    .{
        .suit = .spade,
        .strength = 3,
        .image = .{ .source = @import("images/spade3.zon") },
    },
    .{
        .suit = .spade,
        .strength = 4,
        .image = .{ .source = @import("images/spade4.zon") },
    },
    .{
        .suit = .spade,
        .strength = 5,
        .image = .{ .source = @import("images/spade5.zon") },
    },
    .{
        .suit = .spade,
        .strength = 6,
        .image = .{ .source = @import("images/spade6.zon") },
    },
    .{
        .suit = .spade,
        .strength = 7,
        .image = .{ .source = @import("images/spade7.zon") },
    },
    .{
        .suit = .spade,
        .strength = 8,
        .image = .{ .source = @import("images/spade8.zon") },
    },
    .{
        .suit = .spade,
        .strength = 9,
        .image = .{ .source = @import("images/spade9.zon") },
    },
    .{
        .suit = .spade,
        .strength = 10,
        .image = .{ .source = @import("images/spade10.zon") },
    },
    .{
        .suit = .spade,
        .strength = 11,
        .image = .{ .source = @import("images/spade11.zon") },
    },
    .{
        .suit = .spade,
        .strength = 12,
        .image = .{ .source = @import("images/spade12.zon") },
    },
    .{
        .suit = .spade,
        .strength = 13,
        .image = .{ .source = @import("images/spade13.zon") },
    },
    .{
        .suit = .spade,
        .strength = 14,
        .image = .{ .source = @import("images/spade14.zon") },
    },
    .{
        .suit = .heart,
        .strength = 2,
        .image = .{ .source = @import("images/heart2.zon") },
    },
    .{
        .suit = .heart,
        .strength = 3,
        .image = .{ .source = @import("images/heart3.zon") },
    },
    .{
        .suit = .heart,
        .strength = 4,
        .image = .{ .source = @import("images/heart4.zon") },
    },
    .{
        .suit = .heart,
        .strength = 5,
        .image = .{ .source = @import("images/heart5.zon") },
    },
    .{
        .suit = .heart,
        .strength = 6,
        .image = .{ .source = @import("images/heart6.zon") },
    },
    .{
        .suit = .heart,
        .strength = 7,
        .image = .{ .source = @import("images/heart7.zon") },
    },
    .{
        .suit = .heart,
        .strength = 8,
        .image = .{ .source = @import("images/heart8.zon") },
    },
    .{
        .suit = .heart,
        .strength = 9,
        .image = .{ .source = @import("images/heart9.zon") },
    },
    .{
        .suit = .heart,
        .strength = 10,
        .image = .{ .source = @import("images/heart10.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 2,
        .image = .{ .source = @import("images/diamond2.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 3,
        .image = .{ .source = @import("images/diamond3.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 4,
        .image = .{ .source = @import("images/diamond4.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 5,
        .image = .{ .source = @import("images/diamond5.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 6,
        .image = .{ .source = @import("images/diamond6.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 7,
        .image = .{ .source = @import("images/diamond7.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 8,
        .image = .{ .source = @import("images/diamond8.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 9,
        .image = .{ .source = @import("images/diamond9.zon") },
    },
    .{
        .suit = .diamond,
        .strength = 10,
        .image = .{ .source = @import("images/diamond10.zon") },
    },
},
