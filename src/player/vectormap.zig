const std = @import("std");

const mangle = @import("mangle");
const raylib = @import("raylib");
const raygui = @import("raygui");

const StableKey = @import("parse.zig").StableKey;

const VectorMap = @This();

const Key = raylib.KeyboardKey;

left: Key = .a,
right: Key = .d,
up: Key = .w,
down: Key = .s,

/// returns scalar -1 | 0 | 1
pub fn getHorizontalInput(self: VectorMap) f32 {
    return @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.right)))) -
        @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.left))));
}
/// returns scalar -1 | 0 | 1
pub fn getVerticalInput(self: VectorMap) f32 {
    return @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.down)))) - @as(f32, @floatFromInt(@intFromBool(raylib.isKeyDown(self.up))));
}

/// returns normalized vector of
///     x = -1 | 0 | 1
///     y = -1 | 0 | 1
///     but normalized
pub fn getInput(self: VectorMap) raylib.Vector2 {
    return (raylib.Vector2{ .x = self.getHorizontalInput(), .y = self.getVerticalInput() }).normalize();
}
