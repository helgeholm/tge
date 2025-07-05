data: []const u8,
width: u8,
pub fn height(self: @This()) u8 {
    return @intCast(@divExact(self.data.len, self.width));
}
