const std = @import("std");
const singleton = @import("singleton.zig");
const Sprite = @import("Sprite.zig");
const Object = @import("Object.zig");
const Config = @import("Config.zig");

const Ball = struct {
    sprite: Sprite = .{
        .data = "" ++
            " ,----, " ++
            "| BALL |" ++
            " '----' ",
        .width = 8,
    },
    dx: i16 = 1,
    dy: i16 = 1,
    sw: usize,
    sh: usize,
    pub fn init(x: i16, y: i16, sw: usize, sh: usize) Ball {
        var b = Ball{ .sw = sw, .sh = sh };
        b.sprite.x = x;
        b.sprite.y = y;
        return b;
    }
    pub fn object(self: *Ball) Object {
        return .{
            .ptr = self,
            .sprite = &self.sprite,
            .tick = Ball.tick,
        };
    }
    pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
        var self: *@This() = @ptrCast(@alignCast(ptr));
        if (keys['x']) {
            self.dx = -self.dx;
            self.dy = -self.dy;
        }
        self.sprite.x += self.dx;
        if (self.sprite.x < 0 or self.sprite.x >= self.sw - 7) {
            self.dx = -self.dx;
            self.sprite.x += 2 * self.dx;
        }
        self.sprite.y += self.dy;
        if (self.sprite.y < 0 or self.sprite.y >= self.sh - 2) {
            self.dy = -self.dy;
            self.sprite.y += 2 * self.dy;
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    const config = Config{ .width = 100, .height = 40 };
    var t = try singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var b = Ball.init(0, 0, config.width, config.height);
    var c = Ball.init(40, 27, config.width, config.height);
    t.addObject(b.object());
    t.addObject(c.object());

    try t.run();
}
