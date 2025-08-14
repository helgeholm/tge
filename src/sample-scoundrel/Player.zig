const std = @import("std");
const tge = @import("tge");

const MainBus = @import("MainBus.zig");
const Card = @import("Card.zig");

const lifeX = 1;
const weaponX = 6;
const top = 20;

bus: MainBus,
life: i8 = 20,
weapon: ?*Card = null,
readied: bool = true,
bodies: std.ArrayList(*Card) = undefined,
sheath: tge.Image = .{ .source = @import("images/not_drawn_weapon.zon") },
anim: usize = 0,

pub fn init(self: *@This()) void {
    self.sheath.init(self.bus.alloc);
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
}

pub fn grabWeapon(self: *@This(), card: *Card) void {
    if (self.weapon) |w| {
        self.bus.message("Weapon ({d}) replaced ({d})", .{ w.strength, card.strength });
        self.bus.discard(w);
    } else {
        self.bus.message("Got weapon ({d})", .{card.strength});
    }
    self.weapon = card;
    card.moveTo(weaponX, top, 0);
    self.readied = true;
    for (self.bodies.items) |b| {
        self.bus.discard(b);
        b.moveDelay = self.bus.rng.intRangeLessThan(usize, 0, 30);
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
                self.bus.message("Weapon is too weakened ({d})", .{b.strength});
                return false;
            }
            b.visibleState = .veryDead;
        }
        card.moveTo(
            @intCast(weaponX + self.bodies.items.len + 1),
            top,
            @intCast(self.bodies.items.len + 1),
        );
        card.visibleState = .dead;
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
    self.anim +%= 1;
}

fn drawWeapon(self: @This(), display: *tge.Display) void {
    if (self.weapon) |_| {
        display.text(weaponX + 1, top + 8, "[SPACE]", .hi_white);
        if (self.readied) {
            display.text(weaponX + 1, top + 9, "Sheathe", .white);
        } else {
            display.putImage(&self.sheath, weaponX, top + 1);
            display.text(weaponX + 2, top + 9, "Draw", .white);
        }
    }
}

fn drawLife(self: @This(), display: *tge.Display) void {
    const life: u8 = if (self.life < 0) 0 else @intCast(self.life);
    const bottom: usize = 30;
    const animSpeed: usize = 5 + life;
    const anim: usize = @divFloor(self.anim, animSpeed);
    const bubblesIn: [4][]const u8 = .{ "O", "o ", " o", ". " };
    const bubblesTop: [3][]const u8 = .{ " .", ".:", ": " };
    const fullRows: usize = @intCast(@divFloor(life, 2));
    for (bottom - fullRows..bottom) |uy| {
        const y: isize = @intCast(uy);
        display.text(lifeX + 1, y, bubblesIn[@mod(uy + anim, 4)], .hi_red);
    }
    display.backgroundArea(lifeX + 1, @intCast(bottom - fullRows), 2, @intCast(fullRows), .red);
    if (@mod(life, 2) > 0)
        display.text(lifeX + 1, @as(isize, @intCast(bottom - fullRows - 1)), bubblesTop[@mod(anim, 3)], .hi_red);
    var wbuf: [2]u8 = .{ ' ', ' ' };
    _ = std.fmt.bufPrint(&wbuf, "{d}", .{life}) catch unreachable;
    display.put(lifeX, bottom - 5, wbuf[0], .black);
    display.put(lifeX, bottom - 4, wbuf[1], .black);
}

pub fn draw(ptr: *anyopaque, display: *tge.Display) void {
    const self: *@This() = @ptrCast(@alignCast(ptr));
    self.drawLife(display);
    self.drawWeapon(display);
}
