const std = @import("std");
const tge = @import("tge");
const Config = tge.Config;

const Background = @import("Background.zig");
const Deck = @import("Deck.zig");
const Card = @import("Card.zig");
const Dungeon = @import("Dungeon.zig");
const Room = @import("Room.zig");
const Player = @import("Player.zig");
const Discards = @import("Discards.zig");
const Overlay = @import("Overlay.zig");
const MainBus = @import("MainBus.zig");

const Game = struct {
    background: Background = undefined,
    deck: Deck = undefined,
    dungeon: Dungeon = undefined,
    room: Room = undefined,
    player: Player = undefined,
    discards: Discards = undefined,
    overlay: Overlay = undefined,
    pub fn init(self: *Game, bus: MainBus) void {
        inline for (@typeInfo(Game).@"struct".fields) |field| {
            @field(self, field.name) = field.type{ .bus = bus };
            @field(self, field.name).init();
        }
    }
    pub fn deinit(self: *Game) void {
        inline for (@typeInfo(Game).@"struct".fields) |field| {
            @field(self, field.name).deinit();
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    var random = std.Random.Pcg.init(@bitCast(std.time.milliTimestamp()));
    const config = Config{ .width = 54, .height = 30 };
    var t = try tge.singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var game = Game{};
    var bus = MainBus{
        .ptr = &game,
        .rng = random.random(),
        .alloc = gpa.allocator(),
    };
    inline for (@typeInfo(@TypeOf(bus.vtable)).@"struct".fields) |field| {
        @field(bus.vtable, field.name) = @field(@This(), field.name);
    }
    game.init(bus);
    defer game.deinit();
    t.addAsObject(&game.deck);
    t.addAsObject(&game.background);
    t.addAsObject(&game.discards);
    t.addAsObject(&game.dungeon);
    t.addAsObject(&game.room);
    t.addAsObject(&game.player);
    t.addAsObject(&game.overlay);
    bus.startNewGame();
    try t.run();
}

fn appendMessage(ptr: *anyopaque, msg: []const u8) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.background.message(msg);
}

fn getCards(ptr: *anyopaque) []Card {
    const game: *Game = @ptrCast(@alignCast(ptr));
    return &game.deck.cards;
}

fn discard(ptr: *anyopaque, card: *Card) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.discards.discard(card);
}

fn isBlockedByModal(ptr: *anyopaque) bool {
    const game: *Game = @ptrCast(@alignCast(ptr));
    return game.overlay.isHelping or game.overlay.isLosing or game.overlay.isWinning;
}

fn setLost(ptr: *anyopaque) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    if (!game.overlay.isWinning) {
        game.overlay.isLosing = true;
        game.background.message("Game lost");
    }
}

fn setWon(ptr: *anyopaque) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    if (!game.overlay.isLosing)
        game.overlay.isWinning = true;
}

fn setHelping(ptr: *anyopaque) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.overlay.isHelping = true;
}

fn grabWeapon(ptr: *anyopaque, weaponCard: *Card) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.player.grabWeapon(weaponCard);
}

fn fight(ptr: *anyopaque, monster: *Card) bool {
    const game: *Game = @ptrCast(@alignCast(ptr));
    return game.player.fight(monster);
}

fn heal(ptr: *anyopaque, amount: i6) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.player.heal(amount);
}

fn drawFromDungeon(ptr: *anyopaque) ?*Card {
    const game: *Game = @ptrCast(@alignCast(ptr));
    return game.dungeon.pile.pop();
}

fn putAtBottomOfDungeon(ptr: *anyopaque, card: *Card) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.dungeon.pile.insertAssumeCapacity(0, card);
}

fn startNewGame(ptr: *anyopaque) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
    game.player.reset();
    game.discards.reset();
    game.dungeon.reset();
    game.room.reset();
    game.overlay.isWinning = false;
    game.overlay.isLosing = false;
    game.background.message("Entering new dungeon");
}
