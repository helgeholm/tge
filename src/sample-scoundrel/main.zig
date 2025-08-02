const std = @import("std");
const tge = @import("tge");
const Config = tge.Config;

const Background = @import("Background.zig");
const Deck = @import("Deck.zig");
const Dungeon = @import("Dungeon.zig");
const Room = @import("Room.zig");
const Player = @import("Player.zig");
const Discards = @import("Discards.zig");
const Overlay = @import("Overlay.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    const config = Config{ .width = 100, .height = 40 };
    var t = try tge.singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var rng = std.Random.Pcg.init(@bitCast(std.time.milliTimestamp()));
    var overlay = Overlay{ .random = rng.random() };
    var bg = Background{};
    var discards = Discards{ .allocator = gpa.allocator(), .random = rng.random() };
    discards.init();
    defer discards.deinit();
    var deck = Deck{};
    var dg = Dungeon{ .random = rng.random(), .deck = &deck, .allocator = gpa.allocator() };
    dg.init();
    defer dg.deinit();
    var p = Player{ .overlay = &overlay, .background = &bg, .discards = &discards, .allocator = gpa.allocator() };
    p.init();
    defer p.deinit();
    var rm = Room{ .overlay = &overlay, .background = &bg, .dungeon = &dg, .player = &p, .random = rng.random(), .discards = &discards };
    rm.startNewGame();
    t.addAsObject(&bg);
    t.addAsObject(&discards);
    t.addAsObject(&dg);
    t.addAsObject(&rm);
    t.addAsObject(&p);
    t.addAsObject(&overlay);
    try t.run();
}
