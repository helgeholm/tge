const Sprite = @import("Sprite.zig");

ptr: *anyopaque,
sprite: ?*Sprite = null,
tick: *const fn (ptr: *anyopaque, keys: *[256]bool) void,
