const std = @import("std");

const ImageSource = struct {
    transparency: u8 = 0,
    content: []const u8,
};

source: ImageSource,
height: u16 = undefined,
width: u16 = undefined,
data: []u8 = undefined,

pub fn init(self: *@This(), alloc: std.mem.Allocator) void {
    if (std.mem.indexOfScalar(u8, self.source.content, '\n')) |w| {
        self.width = @intCast(w);
    } else {
        self.width = @intCast(self.source.content.len);
    }
    self.height = @intCast(@divExact(self.source.content.len + 1, self.width + 1));
    self.data = alloc.alloc(u8, self.width * self.height) catch unreachable;
    var it = std.mem.splitScalar(u8, self.source.content, '\n');
    var p: usize = 0;
    while (it.next()) |line| {
        @memcpy(self.data[p .. p + self.width], line);
        p += self.width;
    }
    std.mem.replaceScalar(u8, self.data, self.source.transparency, 0);
}

pub fn deinit(self: *@This(), alloc: std.mem.Allocator) void {
    alloc.free(self.data);
}
