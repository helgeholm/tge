const std = @import("std");
const posix = std.posix;

const Config = @import("Config.zig");
const Display = @import("Display.zig");
const Object = @import("Object.zig");

const stdin = std.io.getStdIn().reader();

allocator: std.mem.Allocator,
display: Display,
keys: [256]bool = undefined,
ticks: usize = 0,
orig_termios: posix.termios,
objects: std.ArrayList(Object),

pub fn init(allocator: std.mem.Allocator, config: Config) !@This() {
    const termios = posix.tcgetattr(0) catch @panic("can't read std.posix.termios - mebbe we not a posix 'puter");
    var new_termios = termios;
    new_termios.lflag.ICANON = false;
    new_termios.lflag.ECHO = false;
    new_termios.cc[@intFromEnum(posix.V.TIME)] = 0;
    new_termios.cc[@intFromEnum(posix.V.MIN)] = 0;
    posix.tcsetattr(0, posix.TCSA.NOW, new_termios) catch unreachable;
    return .{
        .allocator = allocator,
        .orig_termios = termios,
        .display = try Display.init(allocator, config),
        .objects = std.ArrayList(Object).init(allocator),
    };
}

fn obj(clientObjectPtr: anytype) Object {
    const O = @typeInfo(@TypeOf(clientObjectPtr)).pointer.child;
    return if (std.meta.hasMethod(O, "draw"))
        if (std.meta.hasMethod(O, "tick"))
            .{
                .ptr = clientObjectPtr,
                .tick = O.tick,
                .draw = O.draw,
            }
        else
            .{
                .ptr = clientObjectPtr,
                .draw = O.draw,
            }
    else
        .{
            .ptr = clientObjectPtr,
            .tick = O.tick,
        };
}

pub fn deinit(self: *@This()) void {
    self.objects.deinit();
    self.display.deinit(self.allocator);
    posix.tcsetattr(0, posix.TCSA.NOW, self.orig_termios) catch unreachable;
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

pub fn addAsObject(self: *@This(), clientObjectPtr: anytype) void {
    self.addObject(obj(clientObjectPtr));
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
    if (self.keys['Q'])
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
