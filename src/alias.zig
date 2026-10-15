const std = @import("std");

const mangle = @import("mangle");
const raylib = @import("raylib");

pub const Position = mangle.Alias(raylib.Vector2, "position");
pub const Velocity = mangle.Alias(raylib.Vector2, "velocity");

// pub const Speed = mangle.Alias(f32, "speed");
