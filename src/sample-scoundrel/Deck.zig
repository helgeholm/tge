const tge = @import("tge");

pub const Card = struct {
    suit: enum { club, diamond, heart, spade },
    strength: i6, // valid for arithmetic range -31,+32
    sprite: tge.Sprite,
};

cards: [44]Card = .{
    .{
        .suit = .club,
        .strength = 2,
        .sprite = .{ .data = @embedFile("sprites/club2"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 3,
        .sprite = .{ .data = @embedFile("sprites/club3"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 4,
        .sprite = .{ .data = @embedFile("sprites/club4"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 5,
        .sprite = .{ .data = @embedFile("sprites/club5"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 6,
        .sprite = .{ .data = @embedFile("sprites/club6"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 7,
        .sprite = .{ .data = @embedFile("sprites/club7"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 8,
        .sprite = .{ .data = @embedFile("sprites/club8"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 9,
        .sprite = .{ .data = @embedFile("sprites/club9"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 10,
        .sprite = .{ .data = @embedFile("sprites/club10"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 11,
        .sprite = .{ .data = @embedFile("sprites/club11"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 12,
        .sprite = .{ .data = @embedFile("sprites/club12"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 13,
        .sprite = .{ .data = @embedFile("sprites/club13"), .width = 12 },
    },
    .{
        .suit = .club,
        .strength = 14,
        .sprite = .{ .data = @embedFile("sprites/club14"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 2,
        .sprite = .{ .data = @embedFile("sprites/spade2"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 3,
        .sprite = .{ .data = @embedFile("sprites/spade3"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 4,
        .sprite = .{ .data = @embedFile("sprites/spade4"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 5,
        .sprite = .{ .data = @embedFile("sprites/spade5"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 6,
        .sprite = .{ .data = @embedFile("sprites/spade6"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 7,
        .sprite = .{ .data = @embedFile("sprites/spade7"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 8,
        .sprite = .{ .data = @embedFile("sprites/spade8"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 9,
        .sprite = .{ .data = @embedFile("sprites/spade9"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 10,
        .sprite = .{ .data = @embedFile("sprites/spade10"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 11,
        .sprite = .{ .data = @embedFile("sprites/spade11"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 12,
        .sprite = .{ .data = @embedFile("sprites/spade12"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 13,
        .sprite = .{ .data = @embedFile("sprites/spade13"), .width = 12 },
    },
    .{
        .suit = .spade,
        .strength = 14,
        .sprite = .{ .data = @embedFile("sprites/spade14"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 2,
        .sprite = .{ .data = @embedFile("sprites/heart2"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 3,
        .sprite = .{ .data = @embedFile("sprites/heart3"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 4,
        .sprite = .{ .data = @embedFile("sprites/heart4"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 5,
        .sprite = .{ .data = @embedFile("sprites/heart5"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 6,
        .sprite = .{ .data = @embedFile("sprites/heart6"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 7,
        .sprite = .{ .data = @embedFile("sprites/heart7"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 8,
        .sprite = .{ .data = @embedFile("sprites/heart8"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 9,
        .sprite = .{ .data = @embedFile("sprites/heart9"), .width = 12 },
    },
    .{
        .suit = .heart,
        .strength = 10,
        .sprite = .{ .data = @embedFile("sprites/heart10"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 2,
        .sprite = .{ .data = @embedFile("sprites/diamond2"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 3,
        .sprite = .{ .data = @embedFile("sprites/diamond3"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 4,
        .sprite = .{ .data = @embedFile("sprites/diamond4"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 5,
        .sprite = .{ .data = @embedFile("sprites/diamond5"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 6,
        .sprite = .{ .data = @embedFile("sprites/diamond6"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 7,
        .sprite = .{ .data = @embedFile("sprites/diamond7"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 8,
        .sprite = .{ .data = @embedFile("sprites/diamond8"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 9,
        .sprite = .{ .data = @embedFile("sprites/diamond9"), .width = 12 },
    },
    .{
        .suit = .diamond,
        .strength = 10,
        .sprite = .{ .data = @embedFile("sprites/diamond10"), .width = 12 },
    },
},
