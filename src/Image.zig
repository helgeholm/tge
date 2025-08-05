const std = @import("std");

const ImageSource = struct {
    transparency: u8 = 0,
    content: []const u8,
    color: ?[]const u8 = null,
    palette: Palette = .{
        .symbol = ".lrgybmcwG",
        .color = &.{
            .white,
            .strong_black,
            .red,
            .green,
            .yellow,
            .blue,
            .magenta,
            .cyan,
            .strong_white,
            .strong_green,
        },
    },
};

const Palette = struct {
    symbol: []const u8,
    color: []const Color,
};

pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    strong_black,
    strong_red,
    strong_green,
    strong_yellow,
    strong_blue,
    strong_magenta,
    strong_cyan,
    strong_white,
};

source: ImageSource,
height: u16 = undefined,
width: u16 = undefined,
data: []u8 = undefined,
color: []Color = undefined,

pub fn init(self: *@This(), alloc: std.mem.Allocator) void {
    if (self.source.palette.color.len != self.source.palette.symbol.len)
        @panic("invalid palette");
    if (std.mem.indexOfScalar(u8, self.source.content, '\n')) |w| {
        self.width = @intCast(w);
    } else {
        self.width = @intCast(self.source.content.len);
    }
    self.height = @intCast(@divExact(self.source.content.len + 1, self.width + 1));
    self.data = alloc.alloc(u8, self.width * self.height) catch unreachable;
    self.color = alloc.alloc(Color, self.width * self.height) catch unreachable;
    var dit = std.mem.splitScalar(u8, self.source.content, '\n');
    var dp: usize = 0;
    while (dit.next()) |line| {
        @memcpy(self.data[dp .. dp + self.width], line);
        dp += self.width;
    }
    std.mem.replaceScalar(u8, self.data, self.source.transparency, 0);
    if (self.source.color) |colorSrc| {
        var cit = std.mem.splitScalar(u8, colorSrc, '\n');
        var cp: usize = 0;
        while (cit.next()) |line| {
            for (line) |c| {
                var color: ?Color = null;
                for (0..self.source.palette.symbol.len) |ic| {
                    if (c == self.source.palette.symbol[ic])
                        color = self.source.palette.color[ic];
                }
                self.color[cp] = color.?;
                cp += 1;
            }
        }
    } else {
        @memset(self.color, .white);
    }
}

pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
    alloc.free(self.data);
    alloc.free(self.color);
}
