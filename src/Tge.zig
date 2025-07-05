const std = @import("std");
const linux = std.os.linux;

const Config = @import("Config.zig");
const Sprite = @import("Sprite.zig");
const Display = @import("Display.zig");
const Object = @import("Object.zig");

const stdin = std.io.getStdIn().reader();

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
            .sprite = self.sprite,
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

allocator: std.mem.Allocator,
display: Display,
keys: [256]bool = undefined,
ticks: usize = 0,
orig_termios: linux.termios,
b: Ball,
c: Ball,

pub fn init(allocator: std.mem.Allocator, config: Config) !@This() {
    var termios: linux.termios = undefined;
    if (linux.tcgetattr(0, &termios) != 0) @panic("termios read");
    var new_termios = termios;
    new_termios.lflag.ICANON = false;
    new_termios.lflag.ECHO = false;
    new_termios.cc[@intFromEnum(linux.V.TIME)] = 0;
    new_termios.cc[@intFromEnum(linux.V.MIN)] = 0;
    if (linux.tcsetattr(0, linux.TCSA.NOW, &new_termios) != 0) @panic("termios write");
    return .{
        .allocator = allocator,
        .orig_termios = termios,
        .display = try Display.init(allocator, config),
        .b = Ball.init(0, 0, config.width, config.height),
        .c = Ball.init(40, 27, config.width, config.height),
    };
}

pub fn deinit(self: *@This()) void {
    self.display.deinit(self.allocator);
    _ = linux.tcsetattr(0, linux.TCSA.NOW, &self.orig_termios);
}

pub fn run(self: *@This()) !void {
    const FPS60: u64 = 16_666_667;
    var t = std.time.Instant.now() catch unreachable;
    var acc: u64 = 0;
    self.display.check_ready();
    while (true) {
        const now = std.time.Instant.now() catch unreachable;
        const delta: u64 = if (now.order(t) == .gt) now.since(t) else 0;
        t = now;
        acc = @min(delta + acc, FPS60 * 2);
        while (acc > FPS60) {
            acc -= FPS60;
            self.tick();
        }
        self.draw();
        std.time.sleep(FPS60 - acc);
    }
}

pub fn win_resized(self: *@This()) void {
    self.display.check_ready();
}

fn paused(self: @This()) bool {
    return (self.display.state == .unready);
}

fn tick(self: *@This()) void {
    if (self.paused()) return;
    @memset(self.keys[0..], false);
    while (true)
        self.keys[stdin.readByte() catch break] = true;
    if (self.keys['0'])
        self.ticks = 0;
    self.b.object().tick(self.b.object().ptr, &self.keys);
    self.c.object().tick(self.b.object().ptr, &self.keys);
    self.ticks += 1;
}

fn draw(self: *@This()) void {
    self.display.clear();
    const now = std.time.Instant.now() catch unreachable;
    self.display.print(10, 20, "{d},{d}.{d}", .{ self.ticks, now.timestamp.sec, now.timestamp.nsec });
    self.display.blot(&self.b.object().sprite.?);
    self.display.blot(&self.c.object().sprite.?);
    self.display.draw();
}
