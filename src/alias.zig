//! Nondescript aliases, which don't belong to any particular system.

const std = @import("std");

const mangle = @import("mangle");
const raylib = @import("raylib");

// actual types

pub const SquareDimensions = struct { side: f32 };

// 2d vectors

pub const Position = mangle.Alias(raylib.Vector2, "position");
pub const Velocity = mangle.Alias(raylib.Vector2, "velocity");

// scalar quantities

pub const Speed = mangle.Alias(f32, "speed");
pub const Radius = mangle.Alias(f32, "radius");
pub const Angle = mangle.Alias(f32, "theta");

// conditions

pub const Friction = struct {};

// events

pub const Render = struct {};
