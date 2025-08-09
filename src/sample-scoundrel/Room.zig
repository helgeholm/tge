const std = @import("std");
const tge = @import("tge");

const Card = @import("Card.zig");
const MainBus = @import("MainBus.zig");

bus: MainBus,
cards: [4]?*Card = .{ null, null, null, null },
hasDrunk: bool = false,
hasSkipped: bool = false,
hasDeclaredWin: bool = false,

const roomActionKeys: [4]u8 = .{ 'q', 'w', 'e', 'r' };
const top: isize = 15;
const left: isize = 24;

pub fn pull(self: *@This()) void {
    for (0..4) |i| {
        if (self.cards[i] == null)
            self.cards[i] = self.bus.drawFromDungeon();
    }
    self.hasDrunk = false;
}

pub fn reset(self: *@This()) void {
    for (0..4) |i| {
        self.cards[i] = null;
    }
    self.hasDrunk = false;
    self.hasSkipped = false;
    self.hasDeclaredWin = false;
    self.pull();
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (keys['n']) self.bus.startNewGame();
    if (self.bus.isBlockedByModal()) return;
    if (keys['h']) self.bus.setHelping();
    for (0..4) |a| {
        if (keys[roomActionKeys[a]]) if (self.cards[a]) |c| {
            switch (c.suit) {
                .diamond => {
                    self.bus.grabWeapon(c);
                    self.cards[a] = null;
                },
                .heart => {
                    if (self.hasDrunk)
                        self.bus.message("You discard a health potion ({d})", .{c.strength})
                    else
                        self.bus.heal(c.strength);

                    self.hasDrunk = true;
                    self.bus.discard(c);
                    self.cards[a] = null;
                },
                .club, .spade => {
                    if (self.bus.fight(c))
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
            self.bus.message("Can't skip two rooms in a row!", .{});
        } else if (self.cardsRemaining() < 4) {
            self.bus.message("Can only skip full rooms!", .{});
        } else {
            self.hasSkipped = true;
            self.bus.rng.shuffle(?*Card, &self.cards);
            for (0..4) |i| {
                if (self.cards[i]) |c| {
                    self.bus.putAtBottomOfDungeon(c);
                    self.cards[i] = null;
                }
            }
            self.pull();
            self.bus.message("You skip to a new room", .{});
        }
    }
    if (self.cardsRemaining() == 0 and !self.hasDeclaredWin) {
        self.bus.message("You have cleared the dungeon!", .{});
        self.bus.setWon();
        self.hasDeclaredWin = true;
    }
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
            display.text(x + 2, top + 10, action, .white);
            display.text(x + 4, top + 9, "[ ]", .strong_white);
            display.put(x + 5, top + 9, roomActionKeys[i] - 32, .strong_white);
        }
    }
}
