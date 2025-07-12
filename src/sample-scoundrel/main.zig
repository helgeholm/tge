const std = @import("std");
const tge = @import("tge");
const Config = tge.Config;

const Background = @import("Background.zig");
const Deck = @import("Deck.zig");
const Dungeon = @import("Dungeon.zig");
const Room = @import("Room.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    const config = Config{ .width = 100, .height = 40 };
    var t = try tge.singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var rng = std.Random.Pcg.init(@bitCast(std.time.milliTimestamp()));
    var bg = Background{};
    var deck = Deck{};
    var dg = Dungeon{ .deck = &deck, .allocator = gpa.allocator() };
    var rm = Room{ .dungeon = &dg };
    dg.init(rng.random());
    rm.pull();
    t.addAsObject(&bg);
    t.addAsObject(&dg);
    t.addAsObject(&rm);

    try t.run();
}
