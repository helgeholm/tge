const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");
const Dungeon = @import("Dungeon.zig");
const Player = @import("Player.zig");
const Background = @import("Background.zig");
const Discards = @import("Discards.zig");
const Overlay = @import("Overlay.zig");

random: std.Random,
player: *Player,
dungeon: *Dungeon,
background: *Background,
discards: *Discards,
overlay: *Overlay,
cards: [4]?*Deck.Card = .{ null, null, null, null },
hasDrunk: bool = false,
hasSkipped: bool = false,

const roomActionKeys: [4]u8 = .{ 'q', 'w', 'e', 'r' };
const top: isize = 15;
const left: isize = 24;

pub fn pull(self: *@This()) void {
    for (0..4) |i| {
        if (self.cards[i] == null)
            self.cards[i] = self.dungeon.pile.pop();
    }
    self.hasDrunk = false;
}

pub fn startNewGame(self: *@This()) void {
    self.player.reset();
    self.discards.reset();
    self.dungeon.reset();
    for (0..4) |i| {
        self.cards[i] = null;
    }
    self.hasDrunk = false;
    self.hasSkipped = false;
    self.pull();
    self.background.message("New game started!", .{});
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (keys['h']) self.overlay.isHelping = true;
    if (keys['k']) self.overlay.isHelping = false;
    if (self.overlay.isHelping) return;
    for (0..4) |a| {
        if (keys[roomActionKeys[a]]) if (self.cards[a]) |c| {
            switch (c.suit) {
                .diamond => {
                    self.player.grabWeapon(c.*);
                    self.cards[a] = null;
                },
                .heart => {
                    if (self.hasDrunk)
                        self.background.message("You discard a health potion ({d})", .{c.strength})
                    else
                        self.player.heal(c.strength);

                    self.hasDrunk = true;
                    self.discards.discard(c.*);
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
            self.background.message("Can't skip two rooms in a row!", .{});
        } else if (self.cardsRemaining() < 4) {
            self.background.message("Can only skip full rooms!", .{});
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
            self.background.message("You skip to a new room", .{});
        }
    }
    if (keys['n']) {
        self.startNewGame();
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
    const gap = 15;
    for (0..4) |i| {
        if (self.cards[i]) |c| {
            const x = left + @as(isize, @intCast(i)) * gap;
            c.draw(x, top, display);
            const action = switch (c.suit) {
                .heart => if (self.hasDrunk) "Discard" else " Drink",
                .spade, .club => " Fight",
                .diamond => " Wield",
            };
            display.text(x + 2, top + 10, action);
            display.text(x + 4, top + 9, "[ ]");
            display.put(x + 5, top + 9, roomActionKeys[i] - 32);
        }
    }
}
