const std = @import("std");
const tge = @import("tge");
const Card = @import("Card.zig");
const MainBus = @This();

ptr: *anyopaque,
alloc: std.mem.Allocator,
rng: std.Random,
messageBuf: [1024]u8 = undefined,
messageBufP: usize = 0,
vtable: VTable = .{},

const VTable = struct {
    appendMessage: *const fn (*anyopaque, []const u8) void = undefined,
    getCards: *const fn (*anyopaque) []Card = undefined,
    discard: *const fn (*anyopaque, *Card) void = undefined,
    isBlockedByModal: *const fn (*anyopaque) bool = undefined,
    setLost: *const fn (*anyopaque) void = undefined,
    setWon: *const fn (*anyopaque) void = undefined,
    setHelping: *const fn (*anyopaque) void = undefined,
    startNewGame: *const fn (*anyopaque) void = undefined,
    grabWeapon: *const fn (*anyopaque, *Card) void = undefined,
    fight: *const fn (*anyopaque, *Card) bool = undefined,
    heal: *const fn (*anyopaque, i6) void = undefined,
    drawFromDungeon: *const fn (*anyopaque) ?*Card = undefined,
    drawHighZCards: *const fn (*anyopaque, *tge.Display) void = undefined,
    putAtBottomOfDungeon: *const fn (*anyopaque, *Card) void = undefined,
};

pub fn appendMessage(self: MainBus, msg: []const u8) void {
    self.vtable.appendMessage(self.ptr, msg);
}

pub fn getCards(self: MainBus) []Card {
    return self.vtable.getCards(self.ptr);
}

pub fn discard(self: MainBus, card: *Card) void {
    self.vtable.discard(self.ptr, card);
}

pub fn isBlockedByModal(self: MainBus) bool {
    return self.vtable.isBlockedByModal(self.ptr);
}

pub fn setLost(self: MainBus) void {
    self.vtable.setLost(self.ptr);
}

pub fn drawHighZCards(self: MainBus, display: *tge.Display) void {
    self.vtable.drawHighZCards(self.ptr, display);
}

pub fn setWon(self: MainBus) void {
    self.vtable.setWon(self.ptr);
}

pub fn setHelping(self: MainBus) void {
    self.vtable.setHelping(self.ptr);
}

pub fn startNewGame(self: MainBus) void {
    self.vtable.startNewGame(self.ptr);
}

pub fn grabWeapon(self: MainBus, card: *Card) void {
    self.vtable.grabWeapon(self.ptr, card);
}

pub fn fight(self: MainBus, card: *Card) bool {
    return self.vtable.fight(self.ptr, card);
}

pub fn heal(self: MainBus, value: i6) void {
    self.vtable.heal(self.ptr, value);
}

pub fn drawFromDungeon(self: MainBus) ?*Card {
    return self.vtable.drawFromDungeon(self.ptr);
}

pub fn putAtBottomOfDungeon(self: MainBus, card: *Card) void {
    return self.vtable.putAtBottomOfDungeon(self.ptr, card);
}

pub fn message(self: *MainBus, comptime fmt: []const u8, args: anytype) void {
    const fmted = std.fmt.bufPrint(self.messageBuf[self.messageBufP..], fmt, args) catch unreachable;
    self.appendMessage(fmted);
    self.messageBufP += fmted.len;
    if (self.messageBufP > 900) self.messageBufP = 0;
}
