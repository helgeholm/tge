const std = @import("std");
const tge = @import("tge");

const MainBus = @import("MainBus.zig");
const Card = @import("Card.zig");

bus: MainBus,
life: i8 = 20,
weapon: ?*Card = null,
readied: bool = true,
bodies: std.ArrayList(*Card) = undefined,
noWeapon: tge.Image = .{ .source = @import("images/no_weapon.zon") },
sheath: tge.Image = .{ .source = @import("images/not_drawn_weapon.zon") },

pub fn init(self: *@This()) void {
    self.sheath.init(self.bus.alloc);
    self.noWeapon.init(self.bus.alloc);
    self.bodies = std.ArrayList(*Card).init(self.bus.alloc);
}

pub fn reset(self: *@This()) void {
    self.bodies.clearRetainingCapacity();
    self.weapon = null;
    self.readied = false;
    self.life = 20;
}

pub fn deinit(self: *@This()) void {
    self.bodies.deinit();
    self.sheath.deinit(self.bus.alloc);
    self.noWeapon.deinit(self.bus.alloc);
}

pub fn grabWeapon(self: *@This(), card: *Card) void {
    if (self.weapon) |w| {
        self.bus.message("You replace your weapon ({d}) with a new ({d})", .{ w.strength, card.strength });
        self.bus.discard(w);
    } else {
        self.bus.message("You grab a weapon ({d})", .{card.strength});
    }
    self.weapon = card;
    self.readied = true;
    for (self.bodies.items) |b| {
        self.bus.discard(b);
    }
    self.bodies.clearRetainingCapacity();
}

pub fn heal(self: *@This(), strength: i6) void {
    self.life = @min(20, self.life + strength);
    self.bus.message("You heal for {d}", .{strength});
}

pub fn fight(self: *@This(), card: *Card) bool {
    if (self.readied and self.weapon != null) {
        const w = self.weapon.?;
        if (self.bodies.getLastOrNull()) |b| {
            if (card.strength >= b.strength) {
                self.bus.message("Weapon cannot fight enemies {d} or above!", .{b.strength});
                return false;
            }
        }
        const newBody = self.bodies.addOne() catch unreachable;
        newBody.* = card;
        if (card.strength > w.strength)
            self.life -= (card.strength - w.strength);
    } else {
        self.life -= card.strength;
        self.bus.discard(card);
    }
    if (self.life <= 0)
        self.bus.setLost();
    return true;
}

pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    if (self.bus.isBlockedByModal()) return;
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
        for (0..self.bodies.items.len) |i| {
            const b = self.bodies.items[i];
            bx += 1;
            b.drawDead(bx, top, display, i < self.bodies.items.len - 1);
        }
        display.text(left + 1, top + 8, "[SPACE]", .hi_white);
        if (self.readied) {
            display.text(left + 1, top + 9, "Sheathe", .white);
        } else {
            display.putImage(&self.sheath, left, top + 1);
            display.text(left + 2, top + 9, "Draw", .white);
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
        display.text(6, y, ":::::", .hi_red);
    }
    display.backgroundArea(6, @intCast(bottom - fullRows), 5, @intCast(fullRows), .red);
    if (@mod(life, 2) == 1)
        display.text(6, @as(isize, @intCast(bottom - fullRows - 1)), ".....", .hi_red);
    if (life < 10) {
        display.put(3, 34, '0' + life, .hi_white);
    } else {
        display.put(3, 34, '0' + @divFloor(life, 10), .hi_white);
        display.put(3, 35, '0' + @mod(life, 10), .hi_white);
    }
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    self.drawLife(display);
    self.drawWeapon(display);
}
