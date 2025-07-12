const tge = @import("tge");
const Display = tge.Display;

pub fn draw(_: *anyopaque, display: *Display) void {
    const b: isize = @intCast(display.height - 1);
    const r: isize = @intCast(display.width - 1);
    for (0..display.width) |ux| {
        const x: isize = @intCast(ux);
        display.put(x, 0, '#');
        display.put(x, b, '#');
    }
    for (1..display.height - 1) |uy| {
        const y: isize = @intCast(uy);
        display.put(0, y, '#');
        display.put(r, y, '#');
    }
}
