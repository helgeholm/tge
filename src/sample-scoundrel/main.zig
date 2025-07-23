const std = @import("std");
const tge = @import("tge");
const Config = tge.Config;

const Background = @import("Background.zig");
const Deck = @import("Deck.zig");
const Dungeon = @import("Dungeon.zig");
const Room = @import("Room.zig");
const Player = @import("Player.zig");

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
    var p = Player{ .background = &bg };
    var rm = Room{ .background = &bg, .dungeon = &dg, .player = &p, .random = rng.random() };
    dg.init(rng.random());
    defer dg.deinit();
    rm.pull();
    t.addAsObject(&bg);
    t.addAsObject(&dg);
    t.addAsObject(&rm);
    t.addAsObject(&p);

    try t.run();
}
