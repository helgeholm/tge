const std = @import("std");
const tge = @import("tge");

suit: enum { club, diamond, heart, spade },
strength: i6, // valid for arithmetic range -31,+32
image: tge.Image,
idleAnim: u16 = 0,
x: isize = -100,
y: isize = -100,
z: isize = -100,
tx: isize = -100,
ty: isize = -100,
tz: isize = -100,
moveAnim: usize = 0,
moveDelay: usize = 0,
visibleState: enum { alive, dead, veryDead } = .alive,

const MOVE_ANIM_LEN: usize = 15;
const MOVE_ANIM_LEN_f: f32 = @floatFromInt(MOVE_ANIM_LEN);

pub fn tick(self: *@This(), rng: std.Random) void {
    if (self.idleAnim == 0)
        self.idleAnim = rng.intRangeLessThanBiased(u16, 60, 600);
    self.idleAnim -= 1;
    if (self.moveAnim > 0) {
        if (self.moveDelay > 0) {
            self.moveDelay -= 1;
        } else {
            self.moveAnim -= 1;
            if (self.moveAnim == 0) {
                self.x = self.tx;
                self.y = self.ty;
                self.z = self.tz;
            }
        }
    }
}

pub fn moveTo(self: *@This(), x: isize, y: isize, z: isize) void {
    self.tx = x;
    self.ty = y;
    self.tz = z;
    self.moveAnim = MOVE_ANIM_LEN;
}

pub fn draw(self: @This(), display: *tge.Display) void {
    var x = self.x;
    var y = self.y;
    if (self.moveAnim > 0) {
        const scalar: f32 = 1 - @as(f32, @floatFromInt(self.moveAnim)) / MOVE_ANIM_LEN_f;
        const dx: f32 = @floatFromInt(self.tx - self.x);
        const dy: f32 = @floatFromInt(self.ty - self.y);
        x += @intFromFloat(@floor(scalar * dx));
        y += @intFromFloat(@floor(scalar * dy));
    }
    switch (self.visibleState) {
        .alive => {
            display.putImage(&self.image, x, y);
            if (self.idleAnim < 10) {
                switch (self.suit) {
                    .club, .spade => {
                        display.put(x + 3, y + 2, ' ', .white);
                        display.put(x + 5, y + 2, ' ', .white);
                    },
                    else => {},
                }
            }
        },
        .dead => {
            self.drawDead(display, x, y, false);
        },
        .veryDead => {
            self.drawDead(display, x, y, true);
        },
    }
}

pub fn drawDead(self: @This(), display: *tge.Display, x: isize, y: isize, extraDead: bool) void {
    display.putImage(&self.image, x, y);
    switch (self.suit) {
        .club, .spade => {
            display.put(x + 3, y + 2, 'x', .white);
            display.put(x + 5, y + 2, 'x', .white);
        },
        .diamond => {
            display.put(x + 4, y + 0, ' ', .white);
            display.put(x + 3, y + 1, ' ', .white);
            display.put(x + 4, y + 1, '_', .white);
            display.put(x + 3, y + 2, '\\', .white);
        },
        .heart => {
            for (2..7) |ux2| {
                const x2: isize = @intCast(ux2);
                display.put(x + x2, y + 2, ' ', .white);
                display.put(x + x2, y + 3, ' ', .white);
            }
        },
    }
    display.colorArea(x, y, self.image.width, self.image.height, .hi_black);
    display.backgroundArea(x, y, self.image.width, self.image.height, .white);
    if (extraDead) {
        display.colorArea(x, y, 1, self.image.height, .black);
        display.backgroundArea(x, y, 1, self.image.height, .hi_black);
    }
}
