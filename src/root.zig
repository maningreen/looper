const std = @import("std");
const Io = std.Io;

pub const mangle = @import("mangle");
pub const raylib = @import("raylib");
pub const raygui = @import("raygui");

pub const Input = @import("input.zig");
pub const render = @import("render.zig");
pub const alias = @import("alias.zig");
pub const physics = @import("physics.zig");
pub const border = @import("border.zig");
pub const time = @import("time.zig");
pub const color = @import("color.zig");

pub const Player = @import("player.zig");
pub const particle = @import("particle.zig");

pub const camera = @import("camera.zig");

pub const Registry = mangle.Registry(
    &.{
        Player,
        particle.Square,
    },
    &.{
        Input.system,

        render.circle,
        render.player,
        render.square,

        physics.velocity,
        physics.friction,
        physics.rotation.system,

        time.elapsed,
        time.maxLifetime,

        color.fade.system,
        color.transparent.system,

        camera.system,
        border.system,
    },
    Extra,
);

pub const Extra = struct {
    mousePosition: raylib.Vector2 = .zero(),
    windowDimensions: raylib.Vector2 = .zero(),
    camera: raylib.Camera2D = .{
        .offset = .zero(),
        .rotation = 0,
        .target = .zero(),
        .zoom = 1,
    },
    random: std.Random,
};
