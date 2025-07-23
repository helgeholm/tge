const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");
const Background = @import("Background.zig");

life: i8 = 20,
weapon: ?Deck.Card = null,
readied: bool = true,
bodyCount: u5 = 0,
body: ?Deck.Card = null,
background: *Background,

pub fn grabWeapon(self: *@This(), card: Deck.Card) void {
    self.weapon = card;
    self.readied = true;
    self.bodyCount = 0;
    self.body = null;
}

pub fn win(self: *@This()) void {
    self.background.message("Yay you wan!", .{}, 3000);
}

pub fn heal(self: *@This(), strength: i6) void {
    self.life = @min(20, self.life + strength);
}

pub fn fight(self: *@This(), card: Deck.Card) bool {
    if (self.readied and self.weapon != null) {
        const w = self.weapon.?;
        if (self.body) |b| {
            if (card.strength >= b.strength) {
                self.background.message("Current weapon cannot fight enemies strength {d} or above!", .{b.strength}, 300);
                return false;
            }
        }

        self.body = card;
        self.bodyCount += 1;
        if (card.strength > w.strength)
            self.life -= (card.strength - w.strength);
    } else {
        self.life -= card.strength;
    }
    if (self.life <= 0) {
        self.background.message("-- You are dead :( --", .{}, 3000);
    }
    return true;
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (keys[' ']) {
        self.readied = !self.readied;
    }
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    var txtbuf: [15]u8 = undefined;
    const txt = std.fmt.bufPrint(&txtbuf, "(( {d} LIFE ))", .{self.life}) catch unreachable;
    display.text(20, 37, txt);
    display.text(42, 37, "WEAPON");
    if (self.weapon) |w| {
        display.blot(&w.sprite, 40, 29);
        if (self.body) |b| {
            var bx: isize = 44;
            for (0..self.bodyCount) |_| {
                bx += 1;
                display.blot(&b.sprite, bx, 29);
                display.put(bx + 4, 32, 'x');
                display.put(bx + 6, 32, 'x');
            }
        }
        display.text(42, 27, "[SPACE]");
        if (self.readied) {
            display.text(42, 28, "Put away");
        } else {
            display.text(39, 33, "--NOT-DRAWN--");
            display.text(43, 28, "Draw");
        }
    } else {
        display.text(41, 33, "((NONE))");
    }
}
