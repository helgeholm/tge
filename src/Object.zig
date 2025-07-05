const Display = @import("Display.zig");

ptr: *anyopaque,
draw: *const fn (ptr: *anyopaque, display: *Display) void,
tick: *const fn (ptr: *anyopaque, keys: *[256]bool) void,
