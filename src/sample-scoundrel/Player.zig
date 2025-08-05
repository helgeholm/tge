const std = @import("std");
const tge = @import("tge");

const Deck = @import("Deck.zig");
const Background = @import("Background.zig");
const Discards = @import("Discards.zig");
const Overlay = @import("Overlay.zig");

life: i8 = 20,
weapon: ?Deck.Card = null,
readied: bool = true,
allocator: std.mem.Allocator,
bodies: std.ArrayList(Deck.Card) = undefined,
background: *Background,
discards: *Discards,
overlay: *Overlay,
noWeapon: tge.Image = .{ .source = @import("images/no_weapon.zon") },
sheath: tge.Image = .{ .source = @import("images/not_drawn_weapon.zon") },

pub fn init(self: *@This()) void {
    self.sheath.init(self.allocator);
    self.noWeapon.init(self.allocator);
    self.bodies = std.ArrayList(Deck.Card).init(self.allocator);
}

pub fn reset(self: *@This()) void {
    self.bodies.clearRetainingCapacity();
    self.weapon = null;
    self.readied = false;
    self.life = 20;
}

pub fn deinit(self: *@This()) void {
    self.bodies.deinit();
    self.sheath.deinit(self.allocator);
    self.noWeapon.deinit(self.allocator);
}

pub fn grabWeapon(self: *@This(), card: Deck.Card) void {
    if (self.weapon) |w| {
        self.background.message("You replace your weapon ({d}) with a new ({d})", .{ w.strength, card.strength });
        self.discards.discard(w);
    } else {
        self.background.message("You grab a weapon ({d})", .{card.strength});
    }
    self.weapon = card;
    self.readied = true;
    for (self.bodies.items) |b| {
        self.discards.discard(b);
    }
    self.bodies.clearRetainingCapacity();
}

pub fn heal(self: *@This(), strength: i6) void {
    self.life = @min(20, self.life + strength);
    self.background.message("You heal for {d}", .{strength});
}

pub fn fight(self: *@This(), card: Deck.Card) bool {
    if (self.readied and self.weapon != null) {
        const w = self.weapon.?;
        if (self.bodies.getLastOrNull()) |b| {
            if (card.strength >= b.strength) {
                self.background.message("Weapon cannot fight enemies {d} or above!", .{b.strength});
                return false;
            }
        }
        const newBody = self.bodies.addOne() catch unreachable;
        newBody.* = card;
        if (card.strength > w.strength)
            self.life -= (card.strength - w.strength);
    } else {
        self.life -= card.strength;
        self.discards.discard(card);
    }
    if (self.life <= 0)
        self.overlay.isLosing = true;
    return true;
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.overlay.isHelping) return;
    if (keys[' ']) {
        self.readied = !self.readied;
    }
}

fn drawWeapon(self: @This(), display: *tge.Display) void {
    const left = 17;
    const top = 29;
    if (self.weapon) |w| {
        w.draw(left, top, display);
        var bx: isize = left + 4;
        for (self.bodies.items) |b| {
            bx += 1;
            b.drawDead(bx, top, display);
        }
        display.text(left + 2, top + 9, "[SPACE]", .strong_white);
        if (self.readied) {
            display.text(left + 2, top + 10, "Sheathe", .white);
        } else {
            display.putImage(&self.sheath, left + 1, top + 2);
            display.text(left + 3, top + 10, "Draw", .white);
        }
    } else {
        display.putImage(&self.noWeapon, left, top);
    }
}

fn drawLife(self: @This(), display: *tge.Display) void {
    const life: u8 = if (self.life < 0) 0 else @intCast(self.life);
    const bottom: usize = 39;
    const fullRows: usize = @intCast(@divFloor(life, 2));
    for (bottom - fullRows..bottom) |uy| {
        const y: isize = @intCast(uy);
        display.text(6, y, ":::::", .strong_red);
    }
    if (@mod(life, 2) == 1)
        display.text(6, @as(isize, @intCast(bottom - fullRows - 1)), ".....", .strong_red);
    if (life < 10) {
        display.put(3, 34, '0' + life, .strong_white);
    } else {
        display.put(3, 34, '0' + @divFloor(life, 10), .strong_white);
        display.put(3, 35, '0' + @mod(life, 10), .strong_white);
    }
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    self.drawLife(display);
    self.drawWeapon(display);
}
