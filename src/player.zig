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

pub const Player = struct {};

comptime handle: Input.Handler = .{ .table = table },
comptime friction: alias.Friction = .{},
comptime color: raylib.Color = raylib.Color.yellow,
comptime player: Player = .{},

keymap: KeyMap = .{ .left = .s, .right = .f, .up = .e, .down = .d },
position: alias.Position = mangle.alias(alias.Position, raylib.Vector2.init(30, 30)),
velocity: alias.Velocity = mangle.alias(alias.Velocity, raylib.Vector2.zero()),
speed: alias.Speed = mangle.alias(alias.Speed, 1000),

const table = Input.Handler.VTable{
    .getVelocity = getVelocity,
};

fn getVelocity(comptime T: type, playerInput: *T, info: anytype) raylib.Vector2 {
    const deltaV = playerInput.keymap.getInput().scale(playerInput.speed * info.delta);
    return playerInput.velocity.add(deltaV);
}

const KeyMap = struct {
    const Key = raylib.KeyboardKey;

    left: Key,
    right: Key,
    up: Key,
    down: Key,

    /// returns scalar -1 | 0 | 1
    fn getHorizontalInput(self: KeyMap) f32 {
        return @as(
            f32,
            @floatFromInt(@intFromBool(raylib.isKeyDown(
                self.right,
            ))),
        ) -
            @as(f32, @floatFromInt(@intFromBool(
                raylib.isKeyDown(
                    self.left,
                ),
            )));
    }
    /// returns scalar -1 | 0 | 1
    fn getVerticalInput(self: KeyMap) f32 {
        return @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.down)))) - @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.up))));
    }

    /// returns vector of 
    ///     x = -1 | 0 | 1
    ///     y = -1 | 0 | 1
    fn getInput(self: KeyMap) raylib.Vector2 {
        return .{ .x = self.getHorizontalInput(), .y = self.getVerticalInput() };
    }
};
