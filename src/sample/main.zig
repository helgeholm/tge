const std = @import("std");
const tge = @import("tge");
const Sprite = tge.Sprite;
const Config = tge.Config;
const Display = tge.Display;

const GameLogic = struct {
    car: *Car,
    treasure: *Treasure,
    pub fn draw(ptr: *anyopaque, display: *Display) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        var txt_buf: [32]u8 = undefined;
        const txt = std.fmt.bufPrint(&txt_buf, "Meters travelled: {d:.1}", .{self.car.pos_x}) catch unreachable;
        display.text(2, 38, txt);
        if (self.car.driving) {
            display.text(2, 2, "SPACE - stop car");
        } else {
            display.text(2, 2, "SPACE - start car");
            const car_x: i32 = @intFromFloat(self.car.pos_x);
            const tdist = @abs(car_x - self.treasure.pos);
            if (tdist < 3)
                display.text(2, 3, "G     - grab treasure");
        }
    }
    pub fn tick(_: *anyopaque, _: *[256]bool) void {
        //const self: *@This() = @ptrCast(@alignCast(ptr));
    }
};

const Treasure = struct {
    exist: bool = false,
    pos: i32 = -100,
    car: *Car,
    sprite: Sprite = .{
        .data = "[*]",
        .x = -100,
        .y = -100,
        .width = 3,
    },
    random: std.Random,
    pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        const car_x: i32 = @intFromFloat(self.car.pos_x);
        if (car_x - self.pos > 50)
            self.exist = false;
        if (!self.exist) {
            self.exist = true;
            self.sprite.y = self.random.intRangeAtMost(i16, 20, 37);
            self.pos = car_x + self.random.intRangeAtMost(i16, 60, 100);
        }
        self.sprite.x = @intCast(25 + self.pos - car_x);
    }
    pub fn draw(ptr: *anyopaque, display: *Display) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        if (!self.exist) return;
        display.blot(&self.sprite);
    }
};

const Background = struct {
    sw: usize,
    sh: usize,
    car: *Car,
    mountains: Sprite = .{
        .data = @embedFile("sprites/horizon"),
        .x = 0,
        .y = 8,
        .width = 61,
    },
    mountains_x_frac: u16 = 0,
    ground0: []const u8 = "_ _________._______________ _____________.______________________",
    ground1: []const u8 = "=----=-------~~~---=------##------=-------------==----- -----#--",
    pub fn draw(ptr: *anyopaque, display: *Display) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        const local_x: usize = @intFromFloat(self.car.pos_x);
        // horizon
        self.mountains.x = 0 - @as(i16, @intCast(@mod(@divTrunc(local_x, 10), 60)));
        display.blot(&self.mountains);
        self.mountains.x += 60;
        display.blot(&self.mountains);
        self.mountains.x += 60;
        display.blot(&self.mountains);
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
        const ground_i: usize = @mod(local_x, self.ground0.len);
        for (1..self.sw - 1) |ug| {
            const gp = @mod(ground_i + ug, self.ground0.len);
            const g: isize = @intCast(ug);
            display.put(g, 15, self.ground0[gp]);
            display.put(g, 16, self.ground1[gp]);
        }
    }
    pub fn tick(ptr: *anyopaque, _: *[256]bool) void {
        const self: *@This() = @ptrCast(@alignCast(ptr));
        if (!self.car.driving) return;
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
    parked: Sprite = .{
        .data = @embedFile("sprites/car0"),
        .x = 20,
        .y = 13,
        .width = 12,
    },
    frame: usize = 0,
    anim_dur: usize = 0,
    driving: bool = true,
    pos_x: f32 = 0,
    pub fn draw(ptr: *anyopaque, display: *Display) void {
        var self: *@This() = @ptrCast(@alignCast(ptr));
        if (self.driving)
            display.blot(&self.frames[self.frame])
        else
            display.blot(&self.parked);
    }
    pub fn tick(ptr: *anyopaque, keys: *[256]bool) void {
        var self: *@This() = @ptrCast(@alignCast(ptr));
        if (keys[' ']) {
            self.driving = !self.driving;
            self.anim_dur = 0;
        }
        if (self.driving) {
            if (self.anim_dur == 0) {
                self.anim_dur = 30;
                self.frame = @mod(self.frame + 1, self.frames.len);
            }
            self.anim_dur -= 1;
            self.pos_x += 0.1;
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    const config = Config{ .width = 100, .height = 40 };
    var t = try tge.singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var rng = std.Random.Pcg.init(1);

    var car = Car{};
    var bg = Background{ .sw = config.width, .sh = config.height, .car = &car };
    var treasure = Treasure{ .car = &car, .random = rng.random() };
    var gl = GameLogic{ .car = &car, .treasure = &treasure };
    t.addAsObject(&bg);
    t.addAsObject(&car);
    t.addAsObject(&treasure);
    t.addAsObject(&gl);

    try t.run();
}
