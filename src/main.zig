const std = @import("std");
const linux = std.os.linux;
const singleton = @import("singleton.zig");
const Sprite = @import("Sprite.zig");
const Object = @import("Object.zig");
const Config = @import("Config.zig");
const Display = @import("Display.zig");

const Background = struct {
    sw: usize,
    sh: usize,
    mountains: Sprite = .{
        .data = @embedFile("sprites/horizon"),
        .x = 0,
        .y = 8,
        .width = 61,
    },
    mountains_x_frac: u16 = 0,
    ground0: []const u8 = "_ _________._______________ _____________.______________________",
    ground1: []const u8 = "=----=-------~~~---=------##------=-------------==----- -----#--",
    ground_i: usize = 0,
    ground_i_frac: u16 = 0,
    pub fn init(sw: usize, sh: usize) Background {
        return .{ .sw = sw, .sh = sh };
    }
    pub fn object(self: *Background) Object {
        return .{
            .ptr = self,
            .draw = Background.draw,
            .tick = Background.tick,
        };
    }
    pub fn draw(ptr: *anyopaque, display: *Display) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        // horizon
        display.blot(&self.mountains);
        self.mountains.x += 60;
        display.blot(&self.mountains);
        self.mountains.x += 60;
        display.blot(&self.mountains);
        self.mountains.x -= 120;
        // frame
        const b: isize = @intCast(self.sh - 1);
        const r: isize = @intCast(self.sw - 1);
        for (0..self.sw) |ux| {
            const x: isize = @intCast(ux);
            display.put(x, 0, '#');
            display.put(x, b, '#');
        }
        for (1..self.sh - 1) |uy| {
            const y: isize = @intCast(uy);
            display.put(0, y, '#');
            display.put(r, y, '#');
        }
        // ground
        for (1..self.sw - 1) |ug| {
            const gp = @mod(self.ground_i + ug, self.ground0.len);
            const g: isize = @intCast(ug);
            display.put(g, 15, self.ground0[gp]);
            display.put(g, 16, self.ground1[gp]);
        }
    }
    pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        self.ground_i_frac += 1;
        if (self.ground_i_frac > 8) {
            self.ground_i += 1;
            self.ground_i_frac = 0;
        }
        self.mountains_x_frac += 1;
        if (self.mountains_x_frac > 40) {
            self.mountains_x_frac = 0;
            self.mountains.x -= 1;
            if (self.mountains.x < -60) {
                self.mountains.x = 0;
            }
        }
    }
};

const Car = struct {
    frames: [2]Sprite = .{ .{
        .data = @embedFile("sprites/car1"),
        .x = 20,
        .y = 13,
        .width = 12,
    }, .{
        .data = @embedFile("sprites/car2"),
        .x = 20,
        .y = 13,
        .width = 12,
    } },
    frame: usize = 0,
    anim_dur: usize = 0,
    pub fn object(self: *Car) Object {
        return .{
            .ptr = self,
            .tick = Car.tick,
            .draw = Car.draw,
        };
    }
    pub fn draw(ptr: *anyopaque, display: *Display) void {
        var self: *@This() = @ptrCast(@alignCast(ptr));
        display.blot(&self.frames[self.frame]);
    }
    pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
        var self: *@This() = @ptrCast(@alignCast(ptr));
        if (self.anim_dur == 0) {
            self.anim_dur = 30;
            self.frame = @mod(self.frame + 1, self.frames.len);
        }
        self.anim_dur -= 1;
    }
};

pub fn main() !void {
    // only needed when Tge crashes too hard for recovery
    uninit();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    const config = Config{ .width = 100, .height = 40 };
    var t = try singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var bg = Background.init(config.width, config.height);
    var car = Car{};
    t.addObject(bg.object());
    t.addObject(car.object());

    try t.run();
}

pub fn uninit() void {
    var termios: linux.termios = undefined;
    if (linux.tcgetattr(0, &termios) != 0) @panic("termios read");
    termios.lflag.ICANON = true;
    termios.lflag.ECHO = true;
    termios.cc[@intFromEnum(linux.V.MIN)] = 1;
    if (linux.tcsetattr(0, linux.TCSA.NOW, &termios) != 0) @panic("termios write");
}
