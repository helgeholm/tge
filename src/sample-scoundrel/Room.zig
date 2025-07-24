const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");
const Dungeon = @import("Dungeon.zig");
const Player = @import("Player.zig");
const Background = @import("Background.zig");

random: std.Random,
player: *Player,
dungeon: *Dungeon,
background: *Background,
cards: [4]?*Deck.Card = .{ null, null, null, null },
hasDrunk: bool = false,
hasSkipped: bool = false,

const roomActionKeys: [4]u8 = .{ 'q', 'w', 'e', 'r' };
const top: isize = 8;
const left: isize = 30;
const skip: tge.Sprite = .{ .data = @embedFile("sprites/skip"), .width = 10 };

pub fn pull(self: *@This()) void {
    for (0..4) |i| {
        if (self.cards[i] == null)
            self.cards[i] = self.dungeon.pile.pop();
    }
    self.hasDrunk = false;
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    for (0..4) |a| {
        if (keys[roomActionKeys[a]]) if (self.cards[a]) |c| {
            switch (c.suit) {
                .diamond => {
                    self.player.grabWeapon(c.*);
                    self.cards[a] = null;
                },
                .heart => {
                    if (self.hasDrunk)
                        self.background.message("The second health potion had no effect.", .{}, 200)
                    else
                        self.player.heal(c.strength);

                    self.hasDrunk = true;
                    self.cards[a] = null;
                },
                .club, .spade => {
                    if (self.player.fight(c.*))
                        self.cards[a] = null;
                },
            }
        };
        if (self.cardsRemaining() == 1) {
            self.hasSkipped = false;
            self.pull();
        }
    }
    if (keys['s']) {
        if (self.hasSkipped) {
            self.background.message("Can't skip two rooms in a row", .{}, 200);
        } else if (self.cardsRemaining() < 4) {
            self.background.message("Can only skip full rooms", .{}, 200);
        } else {
            self.hasSkipped = true;
            self.random.shuffle(?*Deck.Card, &self.cards);
            for (0..4) |i| {
                if (self.cards[i]) |c| {
                    self.dungeon.pile.insertAssumeCapacity(0, c);
                    self.cards[i] = null;
                }
            }
            self.pull();
        }
    }
    if (self.cardsRemaining() == 0)
        self.player.win();
}

fn cardsRemaining(self: @This()) u3 {
    var remaining: u3 = 0;
    for (0..4) |i| {
        if (self.cards[i] != null)
            remaining += 1;
    }
    return remaining;
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    const gap = 12;
    for (0..4) |i| {
        if (self.cards[i]) |c| {
            const x = left + @as(isize, @intCast(i)) * gap;
            c.draw(x, top + 2, display);
            const action = switch (c.suit) {
                .heart => "Drink",
                .spade => "Fight",
                .club => "Fight",
                .diamond => "Wield",
            };
            display.text(x + 3, top + 1, action);
            display.text(x + 4, top, "[ ]");
            display.put(x + 5, top, roomActionKeys[i] - 32);
        }
    }
    display.text(left + gap * 4 + 5, top, "[S]");
    display.text(left + gap * 4 + 5, top + 1, "Skip");
    display.blot(&skip, left + gap * 4 + 3, top + 3);
}
