const std = @import("std");
const Config = @import("Config.zig");
const Sprite = @import("Sprite.zig");

const DisplayState = enum { unready, ready };

const stdout = std.io.getStdOut().writer();

width: usize,
height: usize,
state: DisplayState = .unready,
winsz: std.posix.winsize = undefined,
data: []u8,

pub fn init(allocator: std.mem.Allocator, config: Config) !@This() {
    var r = @This(){
        .width = config.width,
        .height = config.height,
        .data = try allocator.alloc(u8, config.width * config.height),
    };
    r.read_winsz();
    try stdout.writeAll("\x1b[?25l");
    return r;
}

pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
    stdout.writeAll("\x1b[?25h") catch {};
    allocator.free(self.data);
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
    const txtEnd = @min(txt.len, self.width - x);
    if (txtEnd <= txtStart) return;
    const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    @memcpy(self.data[tpos .. tpos + txtEnd - txtStart], txt[txtStart..txtEnd]);
}

pub inline fn put(self: *@This(), x: isize, y: isize, c: u8) void {
    if (y < 0 or y >= self.height) return;
    if (x < 0 or x >= self.width) return;
    const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    self.data[tpos] = c;
}

pub fn blot(self: *@This(), sprite: *const Sprite, x: i16, y: i16) void {
    for (0..sprite.height()) |sy| {
        const ty = y + @as(isize, @intCast(sy));
        if (ty < 0 or ty >= self.height) continue;
        for (0..sprite.width) |sx| {
            const tx = x + @as(isize, @intCast(sx));
            if (tx < 0 or tx >= self.width) continue;
            const spos: usize = @as(usize, @intCast(sprite.width)) * sy + sx;
            const tpos: usize = @intCast(@as(isize, @intCast(self.width)) * ty + tx);
            if (sprite.data[spos] < 32) continue;
            self.data[tpos] = sprite.data[spos];
        }
    }
}

pub fn print(self: *@This(), x: isize, y: isize, comptime fmt: []const u8, args: anytype) void {
    const pos: usize = @intCast(@as(isize, @intCast(self.width)) * y + x);
    _ = std.fmt.bufPrint(self.data[pos..], fmt, args) catch unreachable;
}

pub fn draw(self: *@This()) void {
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
