const std = @import("std");
const linux = std.os.linux;

const Config = @import("Config.zig");
const Display = @import("Display.zig");
const Object = @import("Object.zig");

const stdin = std.io.getStdIn().reader();

allocator: std.mem.Allocator,
display: Display,
keys: [256]bool = undefined,
ticks: usize = 0,
orig_termios: linux.termios,
objects: std.ArrayList(Object),

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
        .objects = std.ArrayList(Object).init(allocator),
    };
}

pub fn deinit(self: *@This()) void {
    self.objects.deinit();
    self.display.deinit(self.allocator);
    _ = linux.tcsetattr(0, linux.TCSA.NOW, &self.orig_termios);
    // Used to recover from a hard crash where deinit didn't run
    // var termios: linux.termios = undefined;
    // if (linux.tcgetattr(0, &termios) != 0) @panic("termios read");
    // termios.lflag.ICANON = true;
    // termios.lflag.ECHO = true;
    // termios.cc[@intFromEnum(linux.V.TIME)] = 0;
    // termios.cc[@intFromEnum(linux.V.MIN)] = 1;
    // if (linux.tcsetattr(0, linux.TCSA.NOW, &termios) != 0) @panic("termios write");
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
            if (self.tick()) return;
        }
        self.draw();
        std.time.sleep(FPS60 - acc);
    }
}

pub fn win_resized(self: *@This()) void {
    self.display.check_ready();
}

pub fn addObject(self: *@This(), o: Object) void {
    const entry = self.objects.addOne() catch unreachable;
    entry.* = o;
}

fn paused(self: @This()) bool {
    return (self.display.state == .unready);
}

fn tick(self: *@This()) bool {
    if (self.paused()) return false;
    @memset(self.keys[0..], false);
    while (true)
        self.keys[stdin.readByte() catch break] = true;
    if (self.keys['q'])
        return true;
    for (self.objects.items) |o| {
        o.tick(o.ptr, &self.keys);
    }
    self.ticks += 1;
    return false;
}

fn draw(self: *@This()) void {
    self.display.clear();
    for (self.objects.items) |o| {
        o.draw(o.ptr, &self.display);
    }
    self.display.draw();
}
