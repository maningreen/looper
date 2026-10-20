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

pub const Player = @import("player.zig");

pub const Registry = mangle.Registry(
    &.{
        Player,
    },
    &.{
        Input.system,
        render.circle,
        render.player,
        physics.velocity,
        physics.friction,
        border.system,
    },
    Extra,
);

pub const Extra = struct {
    mousePosition: raylib.Vector2 = .zero(),
};
