data: []const u8,
width: u8,
x: i16 = 0,
y: i16 = 0,
pub fn height(self: @This()) u8 {
    return @intCast(@divExact(self.data.len, self.width));
}
