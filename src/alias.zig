const std = @import("std");

const mangle = @import("mangle");
const raylib = @import("raylib");

// 2d vectors

pub const Position = mangle.Alias(raylib.Vector2, "position");
pub const Velocity = mangle.Alias(raylib.Vector2, "velocity");

// scalar quantities

pub const Speed = mangle.Alias(f32, "speed");
pub const Radius = mangle.Alias(f32, "radius");

pub const Elapsed = mangle.Alias(f32, "elapsed");
pub const MaxLifetime = mangle.Alias(f32, "maxLifetime");

// conditions

pub const Friction = struct {};
pub const FollowCamera = struct {};

// events

pub const Render = struct {};
