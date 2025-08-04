const std = @import("std");
const Config = @import("Config.zig");
const Image = @import("Image.zig");

const DisplayState = enum { unready, ready };

const stdout = std.io.getStdOut().writer();

width: isize,
height: isize,
state: DisplayState = .unready,
winsz: std.posix.winsize = undefined,
data: []u8,
color: []Image.Color,

pub fn init(allocator: std.mem.Allocator, config: Config) !@This() {
    var r = @This(){
        .width = config.width,
        .height = config.height,
        .data = try allocator.alloc(u8, @intCast(config.width * config.height)),
        .color = try allocator.alloc(Image.Color, @intCast(config.width * config.height)),
    };
    r.read_winsz();
    try stdout.writeAll("\x1b[?25l");
    return r;
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    stdout.writeAll("\x1b[?25h") catch {};
    allocator.free(self.data);
    allocator.free(self.color);
}

fn read_winsz(self: *@This()) void {
    const rv = std.posix.system.ioctl(
        stdout.context.handle,
        std.posix.system.T.IOCGWINSZ,
        @intFromPtr(&self.winsz),
    );
    if (rv != 0) @panic("IOCTL TIOCGWINSZ failed (can't read terminal size)");
}

pub fn clear(self: *@This()) void {
    @memset(self.data, ' ');
    @memset(self.color, .white);
}

fn draw_unready(self: @This()) !void {
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

pub fn check_ready(self: *@This()) void {
    self.read_winsz();
    self.state = if (self.winsz.row >= self.height and self.winsz.col >= self.width)
        .ready
    else
        .unready;
}

pub inline fn text(self: *@This(), x: isize, y: isize, txt: []const u8) void {
    if (y < 0 or y >= self.height) return;
    const txtStart = @max(0, -x);
    const txtEnd = @min(@as(isize, @intCast(txt.len)), self.width - x);
    if (txtEnd <= txtStart) return;
    const tpos: isize = @as(isize, @intCast(self.width)) * y + x;
    @memcpy(self.data[@intCast(tpos)..@intCast(tpos + txtEnd - txtStart)], txt[@intCast(txtStart)..@intCast(txtEnd)]);
}

pub inline fn put(self: *@This(), x: isize, y: isize, c: u8, color: Image.Color) void {
    if (y < 0 or y >= self.height) return;
    if (x < 0 or x >= self.width) return;
    const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    self.data[tpos] = c;
    self.color[tpos] = color;
}

pub inline fn colorArea(self: *@This(), x: isize, y: isize, width: isize, height: isize, color: Image.Color) void {
    const lx: usize = @intCast(@max(0, x));
    const ly: usize = @intCast(@max(0, y));
    const hx: usize = @intCast(@min(self.width - 1, x + width));
    const hy: usize = @intCast(@min(self.height - 1, y + height));
    for (ly..hy) |uy| {
        for (lx..hx) |ux| {
            const tpos: usize = @as(usize, @intCast(self.width)) * uy + ux;
            self.color[tpos] = color;
        }
    }
}

pub fn putImage(self: *@This(), image: *const Image, x: isize, y: isize) void {
    for (0..image.height) |sy| {
        const ty = y + @as(isize, @intCast(sy));
        if (ty < 0 or ty >= self.height) continue;
        for (0..image.width) |sx| {
            const tx = x + @as(isize, @intCast(sx));
            if (tx < 0 or tx >= self.width) continue;
            const spos: usize = @as(usize, @intCast(image.width)) * sy + sx;
            const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * ty + tx);
            if (image.data[spos] < 32) continue;
            self.data[tpos] = image.data[spos];
            self.color[tpos] = image.color[spos];
        }
    }
}

pub fn print(self: *@This(), x: isize, y: isize, comptime fmt: []const u8, args: anytype) void {
    const pos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    _ = std.fmt.bufPrint(self.data[pos..], fmt, args) catch unreachable;
}

inline fn setColor(color: Image.Color) []const u8 {
    return switch (color) {
        .black => "\x1b[0;30m",
        .red => "\x1b[0;31m",
        .green => "\x1b[0;32m",
        .yellow => "\x1b[0;33m",
        .blue => "\x1b[0;34m",
        .magenta => "\x1b[0;35m",
        .cyan => "\x1b[0;36m",
        .white => "\x1b[0;37m",
        .strong_black => "\x1b[1;30m",
        .strong_red => "\x1b[1;31m",
        .strong_green => "\x1b[1;32m",
        .strong_yellow => "\x1b[1;33m",
        .strong_blue => "\x1b[1;34m",
        .strong_magenta => "\x1b[1;35m",
        .strong_cyan => "\x1b[1;36m",
        .strong_white => "\x1b[1;37m",
    };
}

pub fn draw(self: *@This()) void {
    if (self.state == .unready) {
        self.draw_unready() catch unreachable;
        return;
    }
    stdout.writeAll("\x1b[1;1H\x1b[0;0m") catch unreachable;
    var color: Image.Color = .white;
    var pos: usize = 0;
    stdout.writeAll(setColor(color)) catch unreachable;
    while (pos < self.data.len) {
        const endLine = pos + @as(usize, @intCast(self.width));
        while (pos < endLine) {
            if (self.color[pos] != color) {
                color = self.color[pos];
                stdout.writeAll(setColor(color)) catch unreachable;
            }
            stdout.writeByte(self.data[pos]) catch unreachable;
            pos += 1;
        }
        stdout.writeAll("\x1b[0K\n") catch unreachable;
    }
    stdout.writeAll("\x1b[0J") catch unreachable;
}
