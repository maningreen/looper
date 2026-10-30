const std = @import("std");
const rl = @import("raylib");
const mangle = @import("mangle");
const time = @import("../time.zig");

pub const Node = struct {
    pos: rl.Vector2,

    /// local coordinates relative to position.
    next: rl.Vector2,

    elapsed: time.Elapsed = .{ .elapsed = 0 },
    lifespan: time.MaxLifetime = .{ .max = 3 },

    comptime radius: f32 = 10,
};
