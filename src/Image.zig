const std = @import("std");

pub const Color = enum {
    transparent,
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    hi_black,
    hi_red,
    hi_green,
    hi_yellow,
    hi_blue,
    hi_magenta,
    hi_cyan,
    hi_white,
};

const ImageSource = struct {
    content: []const u8,
    color: ?[]const u8 = null,
    background: ?[]const u8 = null,
    palette: Palette = .{
        .symbol = " .krgybmcwKGRB",
        .color = &.{
            .transparent,
            .white,
            .black,
            .red,
            .green,
            .yellow,
            .blue,
            .magenta,
            .cyan,
            .hi_white,
            .hi_black,
            .hi_green,
            .hi_red,
            .hi_blue,
        },
    },
};

const Palette = struct {
    symbol: []const u8,
    color: []const Color,
};

source: ImageSource,
height: u16 = undefined,
width: u16 = undefined,
data: []u8 = undefined,
color: []Color = undefined,
background: []Color = undefined,

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
    self.background = alloc.alloc(Color, self.width * self.height) catch unreachable;
    var dit = std.mem.splitScalar(u8, self.source.content, '\n');
    var dp: usize = 0;
    while (dit.next()) |line| {
        @memcpy(self.data[dp .. dp + self.width], line);
        dp += self.width;
    }
    readColorMap(self.source.color, self.source.palette, .white, self.color);
    readColorMap(self.source.background, self.source.palette, .transparent, self.background);
}

fn readColorMap(codes: ?[]const u8, palette: Palette, default: Color, colorMap: []Color) void {
    if (codes) |code| {
        var cit = std.mem.splitScalar(u8, code, '\n');
        var cp: usize = 0;
        while (cit.next()) |line| {
            for (line) |c| {
                var color: ?Color = null;
                for (0..palette.symbol.len) |ic| {
                    if (c == palette.symbol[ic])
                        color = palette.color[ic];
                }
                colorMap[cp] = color.?;
                cp += 1;
            }
        }
    } else {
        @memset(colorMap, default);
    }
}

pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
    alloc.free(self.data);
    alloc.free(self.color);
}
