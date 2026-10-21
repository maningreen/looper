const std = @import("std");

const mangle = @import("mangle");
const alias = @import("alias.zig");
const raylib = @import("raylib");
const time = @import("time.zig");

// pub const Base = struct {
// position: alias.Position,
// velocity: alias.Velocity,
// lifetime: time.Elapsed,
// maxLifetime: time.MaxLifetime,
// };

pub const Square = struct {
    color: raylib.Color,
    dimensions: alias.SquareDimensions,
    theta: alias.Rotation = mangle.alias(alias.Rotation, 0),
    position: alias.Position = mangle.alias(alias.Position, raylib.Vector2.zero()),
    velocity: alias.Velocity = mangle.alias(alias.Velocity, raylib.Vector2.zero()),
    lifetime: time.Elapsed = mangle.alias(time.Elapsed, 0),
    maxLifetime: time.MaxLifetime = mangle.alias(time.MaxLifetime, 0),
};
