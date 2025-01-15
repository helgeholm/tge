const std = @import("std");
const linux = std.os.linux;

const Config = struct {
    width: usize,
    height: usize,
};
const DisplayState = enum { unready, ready };
const stdout = std.io.getStdOut().writer();
const stdin = std.io.getStdIn().reader();

const Sprite = struct {
    data: []const u8,
    width: u8,
    pub fn height(self: Sprite) u8 {
        return @intCast(@divExact(self.data.len, self.width));
    }
};

const Ball = struct {
    x: i16 = 5,
    y: i16 = 6,
    dx: i16 = 1,
    dy: i16 = 1,
    sw: usize,
    sh: usize,
    pub fn tick(self: *@This()) void {
        self.x += self.dx;
        if (self.x < 0 or self.x >= self.sw - 7) {
            self.dx = -self.dx;
            self.x += 2 * self.dx;
        }
        self.y += self.dy;
        if (self.y < 0 or self.y >= self.sh - 2) {
            self.dy = -self.dy;
            self.y += 2 * self.dy;
        }
    }
    pub fn draw(self: @This(), display: *Display) void {
        const sprite: Sprite = .{
            .data = "" ++
                " ,----, " ++
                "| BALL |" ++
                " '----' ",
            .width = 8,
        };
        display.blot(self.x, self.y, &sprite);
    }
};

pub const Tge = struct {
    allocator: std.mem.Allocator,
    display: Display,
    ticks: usize = 0,
    orig_termios: linux.termios,
    b: Ball,
    c: Ball,
    pub fn init(allocator: std.mem.Allocator, config: Config) !Tge {
        var termios: linux.termios = undefined;
        if (linux.tcgetattr(0, &termios) != 0) @panic("termios read");
        var new_termios = termios;
        new_termios.lflag.ICANON = false;
        new_termios.lflag.ECHO = false;
        new_termios.cc[@intFromEnum(linux.V.TIME)] = 0;
        new_termios.cc[@intFromEnum(linux.V.MIN)] = 0;
        if (linux.tcsetattr(0, linux.TCSA.NOW, &new_termios) != 0) @panic("termios write");
        return Tge{
            .allocator = allocator,
            .orig_termios = termios,
            .display = try Display.init(allocator, config),
            .b = .{ .sw = config.width, .sh = config.height },
            .c = .{ .x = 40, .y = 27, .sw = config.width, .sh = config.height },
        };
    }
    pub fn deinit(self: *Tge) void {
        self.display.deinit(self.allocator);
        _ = linux.tcsetattr(0, linux.TCSA.NOW, &self.orig_termios);
    }
    pub fn run(self: *Tge) !void {
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
            std.Thread.sleep(FPS60 - acc);
        }
    }
    pub fn win_resized(self: *Tge) void {
        self.display.check_ready();
    }
    fn paused(self: Tge) bool {
        return (self.display.state == .unready);
    }
    fn tick(self: *Tge) void {
        if (self.paused()) return;
        if (stdin.readByte() catch undefined == '0') {
            self.ticks = 0;
        }
        self.b.tick();
        self.c.tick();
        self.ticks += 1;
    }
    fn draw(self: *Tge) void {
        self.display.clear();
        const now = std.time.Instant.now() catch unreachable;
        self.display.print(10, 20, "{d},{d}.{d}", .{ self.ticks, now.timestamp.sec, now.timestamp.nsec });
        self.b.draw(&self.display);
        self.c.draw(&self.display);
        self.display.draw();
    }
};

const Display = struct {
    width: usize,
    height: usize,
    state: DisplayState = .unready,
    winsz: std.posix.winsize = undefined,
    data: []u8,
    pub fn init(allocator: std.mem.Allocator, config: Config) !Display {
        var r = Display{
            .width = config.width,
            .height = config.height,
            .data = try allocator.alloc(u8, config.width * config.height),
        };
        r.read_winsz();
        try stdout.writeAll("\x1b[?25l");
        return r;
    }
    pub fn deinit(self: *Display, allocator: std.mem.Allocator) void {
        stdout.writeAll("\x1b[?25h") catch {};
        allocator.free(self.data);
    }
    fn read_winsz(self: *Display) void {
        const rv = std.os.linux.ioctl(
            stdout.context.handle,
            std.os.linux.T.IOCGWINSZ,
            @intFromPtr(&self.winsz),
        );
        if (rv != 0) @panic("IOCTL TIOCGWINSZ failed (can't read terminal size)");
    }
    pub fn clear(self: *Display) void {
        @memset(self.data, ' ');
    }
    fn draw_unready(self: Display) !void {
        try stdout.writeAll("\x1b[1;1H");
        const mid_y = @divTrunc(self.winsz.row, 2);
        for (0..mid_y * self.winsz.col) |_| try stdout.writeAll(" ");
        var txtbuf = [_]u8{' '} ** 80;
        const txt = try std.fmt.bufPrint(&txtbuf, "WIDTH/HEIGHT ({d}/{d}) MUST BE AT LEAST {d}/{d}", .{ self.winsz.col, self.winsz.row, self.width, self.height });
        const x = if (txt.len > self.winsz.col) 0 else @divTrunc(self.winsz.col - txt.len, 2);
        for (0..x) |_| try stdout.writeAll(" ");
        try stdout.writeAll(txt);
        for (0..self.winsz.col - txt.len - x) |_| try stdout.writeAll(" ");
        try std.fmt.format(stdout, "\x1b[{d};1H", .{mid_y + 2});
        for (0..(self.winsz.row - mid_y - 1) * self.winsz.col) |_| try stdout.writeAll(" ");
        try stdout.writeAll("\x1b[1;1H");
    }
    pub fn check_ready(self: *Display) void {
        self.read_winsz();
        self.state = if (self.winsz.row >= self.height and self.winsz.col >= self.width)
            .ready
        else
            .unready;
    }
    pub fn blot(self: *Display, x: isize, y: isize, sprite: *const Sprite) void {
        for (0..sprite.height()) |sy| {
            const ty = y + @as(isize, @intCast(sy));
            if (ty < 0 or ty >= self.height) continue;
            for (0..sprite.width) |sx| {
                const tx = x + @as(isize, @intCast(sx));
                if (tx < 0 or tx >= self.width) continue;
                const spos: usize = @as(usize, @intCast(sprite.width)) * sy + sx;
                const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * ty + tx);
                self.data[tpos] = sprite.data[spos];
            }
        }
    }
    pub fn print(self: *Display, x: isize, y: isize, comptime fmt: []const u8, args: anytype) void {
        const pos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
        _ = std.fmt.bufPrint(self.data[pos..], fmt, args) catch unreachable;
    }
    pub fn draw(self: *Display) void {
        if (self.state == .unready) {
            self.draw_unready() catch unreachable;
            return;
        }
        var pos: usize = 0;
        stdout.writeAll("\x1b[1;1H") catch unreachable;
        while (pos < self.data.len) {
            stdout.writeAll(self.data[pos .. pos + self.width]) catch unreachable;
            stdout.writeAll("\x1b[0K\n") catch unreachable;
            pos += self.width;
        }
        stdout.writeAll("\x1b[0J") catch unreachable;
    }
};
