const std = @import("std");

const mangle = @import("mangle");
const rl = @import("raylib");

const alias = @import("alias.zig");
const Player = @import("player.zig");
const border = @import("border.zig");
const physics = @import("physics.zig");

pub const circle = @import("render/circle.zig");
pub const square = @import("render/square.zig");
pub const player = @import("render/player.zig");
