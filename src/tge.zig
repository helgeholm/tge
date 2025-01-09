const std = @import("std");

const DisplayState = enum { unready, ready };
const stdout = std.io.getStdOut().writer();

pub const Tge = struct {
    allocator: std.mem.Allocator,
    display: Display,
    ticks: usize = 0,
    pub fn deinit(self: *Tge) void {
        std.debug.print("i am self {}", .{self.display});
    }
    pub fn run(self: *Tge) !void {
        const FPS60: u64 = 16_666_667;
        var t = std.time.Instant.now() catch unreachable;
        var acc: u64 = 0;
        self.display.check_ready();
        while (true) {
            const now = std.time.Instant.now() catch unreachable;
            const delta: u64 = if (now.order(t) == .gt) now.since(t) else 0;
            t = now;
            acc = @min(delta + acc, FPS60 * 2);
            while (acc > FPS60) {
                acc -= FPS60;
                self.tick();
            }
            self.draw();
            std.Thread.sleep(FPS60 - acc);
        }
    }
    pub fn win_resized(self: *Tge) void {
        self.display.check_ready();
    }
    fn paused(self: Tge) bool {
        return (self.display.state == .unready);
    }
    fn tick(self: *Tge) void {
        if (self.paused()) return;
        self.ticks += 1;
    }
    fn draw(self: *Tge) void {
        self.display.draw(self.ticks);
    }
};

const Display = struct {
    width: usize,
    height: usize,
    state: DisplayState = .unready,
    winsz: std.posix.winsize = undefined,
    fn read_winsz(self: *Display) void {
        const rv = std.os.linux.ioctl(
            stdout.context.handle,
            std.os.linux.T.IOCGWINSZ,
            @intFromPtr(&self.winsz),
        );
        if (rv != 0) @panic("IOCTL TIOCGWINSZ failed (can't read terminal size)");
    }
    fn draw_unready(self: Display) void {
        std.debug.print("\x1b[1;1Hplz at least {d}x{d}, current {}   \n", .{ self.width, self.height, self.winsz });
    }
    pub fn check_ready(self: *Display) void {
        self.read_winsz();
        self.state = if (self.winsz.row >= self.height and self.winsz.col >= self.width)
            .ready
        else
            .unready;
    }
    pub fn draw(self: Display, some_shit: usize) void {
        if (self.state == .unready) {
            self.draw_unready();
            return;
        }
        const now = std.time.Instant.now() catch unreachable;
        std.debug.print("\x1b[1;1H{d},{d}.{d}            \n", .{ some_shit, now.timestamp.sec, now.timestamp.nsec });
    }
};
