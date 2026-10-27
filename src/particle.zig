const std = @import("std");

const mangle = @import("mangle");
const physics = @import("physics.zig");
const alias = @import("alias.zig");
const raylib = @import("raylib");
const time = @import("time.zig");
const color = @import("color.zig");

// pub const Base = struct {
// position: alias.Position,
// velocity: alias.Velocity,
// lifetime: time.Elapsed,
// maxLifetime: time.MaxLifetime,
// };

pub const Square = struct {
    color: raylib.Color,
    dimensions: alias.SquareDimensions,
    theta: physics.rotation.Rotation = .{ .theta = 0 },
    deltaTheta: physics.rotation.AngularMomentum = .{ .deltatheta = 30 },
    position: alias.Position = mangle.alias(alias.Position, raylib.Vector2.zero()),
    velocity: alias.Velocity = mangle.alias(alias.Velocity, raylib.Vector2.zero()),
    lifetime: time.Elapsed = mangle.alias(time.Elapsed, 0),
    maxLifetime: time.MaxLifetime = mangle.alias(time.MaxLifetime, 3),
    comptime fade: color.fade.Fade = .{ .strength = 1.5 },
    comptime transparent: color.transparent.Transparent = .{}
};
