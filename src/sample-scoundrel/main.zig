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
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak)
        std.log.err("Memory leak detected on exit", .{});

    var random = std.Random.Pcg.init(@bitCast(std.time.milliTimestamp()));
    const config = Config{ .width = 100, .height = 40 };
    var t = try tge.singleton.init(gpa.allocator(), config);
    defer t.deinit();

    var game = Game{};
    const bus = MainBus{
        .ptr = &game,
        .rng = random.random(),
        .alloc = gpa.allocator(),
        .vtable = .{
            .appendMessage = appendMessage,
            .getCards = getCards,
            .discard = discard,
            .isBlockedByModal = isBlockedByModal,
            .setLost = setLost,
            .setWon = setWon,
            .setHelping = setHelping,
            .grabWeapon = grabWeapon,
            .drawFromDungeon = drawFromDungeon,
            .putAtBottomOfDungeon = putAtBottomOfDungeon,
            .startNewGame = startNewGame,
            .fight = fight,
            .heal = heal,
        },
    };
    game.overlay = Overlay{ .bus = bus };
    game.background = Background{ .bus = bus };
    game.discards = Discards{ .bus = bus };
    game.deck = Deck{ .bus = bus };
    game.dungeon = Dungeon{ .bus = bus };
    game.player = Player{ .bus = bus };
    game.room = Room{ .bus = bus };
    game.player.init();
    game.overlay.init();
    game.background.init();
    game.discards.init();
    game.deck.init();
    game.dungeon.init();
    defer game.player.deinit();
    defer game.overlay.deinit();
    defer game.background.deinit();
    defer game.discards.deinit();
    defer game.deck.deinit();
    defer game.dungeon.deinit();
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
    game.overlay.isLosing = true;
}

fn setWon(ptr: *anyopaque) void {
    const game: *Game = @ptrCast(@alignCast(ptr));
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
    game.background.message("New game started!");
}
