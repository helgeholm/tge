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
    self.background.message("Yay you wan!", .{});
}

pub fn heal(self: *@This(), strength: i6) void {
    self.life = @min(20, self.life + strength);
}

pub fn fight(self: *@This(), card: Deck.Card) bool {
    if (self.readied and self.weapon != null) {
        const w = self.weapon.?;
        if (self.body) |b| {
            if (card.strength >= b.strength) {
                self.background.message("Weapon cannot fight enemies {d} or above!", .{b.strength});
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
        self.background.message("-- You are dead :( --", .{});
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
    const left = 17;
    const top = 29;
    if (self.weapon) |w| {
        w.draw(left, top, display);
        if (self.body) |b| {
            var bx: isize = left + 4;
            for (0..self.bodyCount) |_| {
                bx += 1;
                b.drawDead(bx, top, display);
            }
        }
        display.text(left + 2, top + 9, "[SPACE]");
        if (self.readied) {
            display.text(left + 2, top + 10, "Sheathe");
        } else {
            display.blot(&self.sheath, left, top + 3);
            display.text(left + 3, top + 10, "Draw");
        }
    } else {
        display.blot(&self.noWeapon, left, top);
    }
}

fn drawLife(self: @This(), display: *tge.Display) void {
    const life: u8 = if (self.life < 0) 0 else @intCast(self.life);
    const bottom: usize = 39;
    const fullRows: usize = @intCast(@divFloor(life, 2));
    for (bottom - fullRows..bottom) |uy| {
        const y: isize = @intCast(uy);
        display.text(6, y, ":::::");
    }
    if (@mod(life, 2) == 1)
        display.text(6, @as(isize, @intCast(bottom - fullRows - 1)), ".....");
    if (life < 10) {
        display.put(3, 34, '0' + life);
    } else {
        display.put(3, 34, '0' + @divFloor(life, 10));
        display.put(3, 35, '0' + @mod(life, 10));
    }
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    self.drawLife(display);
    self.drawWeapon(display);
}
