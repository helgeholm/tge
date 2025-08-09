const tge = @import("tge");

suit: enum { club, diamond, heart, spade },
strength: i6, // valid for arithmetic range -31,+32
image: tge.Image,
anim: u16 = 0,

pub fn draw(self: @This(), x: isize, y: isize, display: *tge.Display) void {
    display.putImage(&self.image, x, y);
    if (self.anim < 10) {
        switch (self.suit) {
            .club, .spade => {
                display.put(x + 4, y + 3, ' ', .white);
                display.put(x + 6, y + 3, ' ', .white);
            },
            else => {},
        }
    }
}

pub fn drawDead(self: @This(), x: isize, y: isize, display: *tge.Display) void {
    display.putImage(&self.image, x, y);
    switch (self.suit) {
        .club, .spade => {
            display.put(x + 4, y + 3, 'x', .white);
            display.put(x + 6, y + 3, 'x', .white);
        },
        .diamond => {
            display.put(x + 5, y + 1, ' ', .white);
            display.put(x + 4, y + 2, ' ', .white);
            display.put(x + 5, y + 2, '_', .white);
            display.put(x + 4, y + 3, '\\', .white);
        },
        .heart => {
            for (3..8) |ux2| {
                const x2: isize = @intCast(ux2);
                display.put(x + x2, y + 3, ' ', .white);
                display.put(x + x2, y + 4, ' ', .white);
            }
        },
    }
    display.colorArea(x, y, self.image.width, self.image.height, .white);
}
