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
background: []Image.Color,

pub fn init(allocator: std.mem.Allocator, config: Config) !@This() {
    var r = @This(){
        .width = config.width,
        .height = config.height,
        .data = try allocator.alloc(u8, @intCast(config.width * config.height)),
        .color = try allocator.alloc(Image.Color, @intCast(config.width * config.height)),
        .background = try allocator.alloc(Image.Color, @intCast(config.width * config.height)),
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
    @memset(self.background, .black);
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

pub inline fn text(self: *@This(), x: isize, y: isize, txt: []const u8, color: Image.Color) void {
    if (y < 0 or y >= self.height) return;
    const txtStart = @max(0, -x);
    const txtEnd = @min(@as(isize, @intCast(txt.len)), self.width - x);
    if (txtEnd <= txtStart) return;
    const tpos: isize = self.width * y + x;
    const begin: usize = @intCast(tpos);
    const end: usize = @intCast(tpos + txtEnd - txtStart);
    @memcpy(self.data[begin..end], txt[@intCast(txtStart)..@intCast(txtEnd)]);
    @memset(self.color[begin..end], color);
}

pub inline fn put(self: *@This(), x: isize, y: isize, c: u8, color: Image.Color) void {
    if (y < 0 or y >= self.height) return;
    if (x < 0 or x >= self.width) return;
    const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    self.data[tpos] = c;
    self.color[tpos] = color;
}

pub inline fn backgroundArea(self: *@This(), x: isize, y: isize, width: isize, height: isize, color: Image.Color) void {
    const lx: usize = @intCast(@max(0, x));
    const ly: usize = @intCast(@max(0, y));
    const hx: usize = @intCast(@min(self.width, x + width));
    const hy: usize = @intCast(@min(self.height, y + height));
    for (ly..hy) |uy| {
        for (lx..hx) |ux| {
            const tpos: usize = @as(usize, @intCast(self.width)) * uy + ux;
            self.background[tpos] = color;
        }
    }
}

pub inline fn colorArea(self: *@This(), x: isize, y: isize, width: isize, height: isize, color: Image.Color) void {
    const lx: usize = @intCast(@max(0, x));
    const ly: usize = @intCast(@max(0, y));
    const hx: usize = @intCast(@min(self.width, x + width));
    const hy: usize = @intCast(@min(self.height, y + height));
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
            if (image.color[spos] != .transparent) {
                if (image.data[spos] >= 32)
                    self.data[tpos] = image.data[spos];
                self.color[tpos] = image.color[spos];
                if (image.background[spos] != .transparent)
                    self.background[tpos] = image.background[spos];
            }
        }
    }
}

pub fn print(self: *@This(), x: isize, y: isize, comptime fmt: []const u8, args: anytype) void {
    const pos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    _ = std.fmt.bufPrint(self.data[pos..], fmt, args) catch unreachable;
}

inline fn fgColor(color: Image.Color) []const u8 {
    return switch (color) {
        .transparent => @panic("should not be called"),
        .black => "\x1b[30m",
        .red => "\x1b[31m",
        .green => "\x1b[32m",
        .yellow => "\x1b[33m",
        .blue => "\x1b[34m",
        .magenta => "\x1b[35m",
        .cyan => "\x1b[36m",
        .white => "\x1b[37m",
        .hi_black => "\x1b[90m",
        .hi_red => "\x1b[91m",
        .hi_green => "\x1b[92m",
        .hi_yellow => "\x1b[93m",
        .hi_blue => "\x1b[94m",
        .hi_magenta => "\x1b[95m",
        .hi_cyan => "\x1b[96m",
        .hi_white => "\x1b[97m",
    };
}

inline fn bgColor(color: Image.Color) []const u8 {
    return switch (color) {
        .transparent => @panic("should not be called"),
        .black => "\x1b[40m",
        .red => "\x1b[41m",
        .green => "\x1b[42m",
        .yellow => "\x1b[43m",
        .blue => "\x1b[44m",
        .magenta => "\x1b[45m",
        .cyan => "\x1b[46m",
        .white => "\x1b[47m",
        .hi_black => "\x1b[100m",
        .hi_red => "\x1b[101m",
        .hi_green => "\x1b[102m",
        .hi_yellow => "\x1b[103m",
        .hi_blue => "\x1b[104m",
        .hi_magenta => "\x1b[105m",
        .hi_cyan => "\x1b[106m",
        .hi_white => "\x1b[107m",
    };
}

pub fn draw(self: *@This()) void {
    if (self.state == .unready) {
        self.draw_unready() catch unreachable;
        return;
    }
    stdout.writeAll("\x1b[1;1H\x1b[0;0m") catch unreachable;
    var color: Image.Color = .white;
    var background: Image.Color = .black;
    var pos: usize = 0;
    stdout.writeAll(fgColor(color)) catch unreachable;
    stdout.writeAll(bgColor(background)) catch unreachable;
    while (pos < self.data.len) {
        const endLine = pos + @as(usize, @intCast(self.width));
        while (pos < endLine) {
            if (self.color[pos] != color or self.background[pos] != background) {
                color = self.color[pos];
                background = self.background[pos];
                stdout.writeAll(fgColor(color)) catch unreachable;
                stdout.writeAll(bgColor(background)) catch unreachable;
            }
            stdout.writeByte(self.data[pos]) catch unreachable;
            pos += 1;
        }
        color = .white;
        background = .black;
        stdout.writeAll(fgColor(color)) catch unreachable;
        stdout.writeAll(bgColor(background)) catch unreachable;
        stdout.writeAll("\x1b[0K\n") catch unreachable;
    }
    stdout.writeAll("\x1b[0J") catch unreachable;
}
