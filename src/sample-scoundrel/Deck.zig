const std = @import("std");
const tge = @import("tge");

pub const Card = struct {
    suit: enum { club, diamond, heart, spade },
    strength: i6, // valid for arithmetic range -31,+32
    image: tge.Image,
    pub fn draw(self: @This(), x: isize, y: isize, display: *tge.Display) void {
        display.putImage(&self.image, x, y);
    }
    pub fn drawDead(self: @This(), x: isize, y: isize, display: *tge.Display) void {
        display.putImage(&self.image, x, y);
        switch (self.suit) {
            .club, .spade => {
                display.put(x + 4, y + 3, 'x', .white);
                display.put(x + 6, y + 3, 'x', .white);
            },
            .diamond => {
                display.put(x + 5, y + 1, ' ', .white);
                display.put(x + 4, y + 2, ' ', .white);
                display.put(x + 5, y + 2, '_', .white);
                display.put(x + 4, y + 3, '\\', .white);
            },
            .heart => {
                for (3..8) |ux2| {
                    const x2: isize = @intCast(ux2);
                    display.put(x + x2, y + 3, ' ', .white);
                    display.put(x + x2, y + 4, ' ', .white);
                }
            },
        }
        display.colorArea(x, y, self.image.width, self.image.height, .white);
    }
};

pub fn init(self: *@This(), alloc: std.mem.Allocator) void {
    for (&self.cards) |*c| {
        c.image.init(alloc);
    }
}

pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
    for (&self.cards) |*c| {
        c.image.deinit(alloc);
    }
}

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
