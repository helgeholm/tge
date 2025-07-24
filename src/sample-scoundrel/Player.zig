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
noWeapon: tge.Sprite = .{ .data = @embedFile("sprites/no_weapon"), .width = 12 },
sheath: tge.Sprite = .{ .data = @embedFile("sprites/not_drawn_weapon"), .width = 13 },

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

fn drawWeapon(self: @This(), display: *tge.Display) void {
    const left = 10;
    const top = 20;
    if (self.weapon) |w| {
        w.draw(left, top + 2, display);
        if (self.body) |b| {
            var bx: isize = left + 4;
            for (0..self.bodyCount) |_| {
                bx += 1;
                b.drawDead(bx, top + 2, display);
            }
        }
        display.text(left + 2, top, "[SPACE]");
        if (self.readied) {
            display.text(left + 2, top + 1, "Sheathe");
        } else {
            display.blot(&self.sheath, left, top + 5);
            display.text(left + 3, top + 1, "Draw");
        }
    } else {
        display.blot(&self.noWeapon, left, top + 2);
    }
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    var txtbuf: [15]u8 = undefined;
    const txt = std.fmt.bufPrint(&txtbuf, "(( {d} LIFE ))", .{self.life}) catch unreachable;
    display.text(20, 37, txt);
    self.drawWeapon(display);
}
