const Display = @import("Display.zig");

ptr: *anyopaque,
draw: *const fn (ptr: *anyopaque, display: *Display) void = noop_draw,
tick: *const fn (ptr: *anyopaque, keys: *[256]bool) void = noop_tick,

fn noop_draw(_: *anyopaque, _: *Display) void {}
fn noop_tick(_: *anyopaque, _: *[256]bool) void {}
