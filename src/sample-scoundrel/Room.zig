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
hasFled: bool = false,

const roomActionKeys: [4]u8 = .{ 'q', 'w', 'e', 'r' };

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
        if (self.cardsLeft() == 1) {
            self.hasFled = false;
            self.pull();
        }
    }
    if (keys['f'] and !self.hasFled and self.cardsLeft() == 4) {
        self.hasFled = true;
        self.random.shuffle(?*Deck.Card, &self.cards);
        for (0..4) |i| {
            if (self.cards[i]) |c| {
                self.dungeon.pile.insertAssumeCapacity(0, c);
                self.cards[i] = null;
            }
        }
        self.pull();
    }
    if (self.cardsLeft() == 0)
        self.player.win();
}

fn cardsLeft(self: @This()) u3 {
    var left: u3 = 0;
    for (0..4) |i| {
        if (self.cards[i] != null)
            left += 1;
    }
    return left;
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    for (0..4) |i| {
        if (self.cards[i]) |c| {
            const x = 38 + @as(isize, @intCast(i)) * 10;
            const y = 15;
            display.blot(&c.sprite, x, y);
            const action = switch (c.suit) {
                .heart => "Drink",
                .spade => "Fight",
                .club => "Fight",
                .diamond => "Wield",
            };
            display.text(x + 3, y - 1, action);
            display.text(x + 4, y - 2, "[ ]");
            display.put(x + 5, y - 2, roomActionKeys[i] - 32);
        }
    }
    display.text(83, 19, "[F]");
    display.text(83, 20, "Flee");
}
