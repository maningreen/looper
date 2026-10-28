const std = @import("std");
const rl = @import("raylib");

const render = @import("../render.zig");
const color = @import("../color.zig");
const alias = @import("../alias.zig");

comptime trans: color.transparent.Transparent = .{},
comptime flag: render.player.body.RenderFlag = .{ .dot = false },

position: alias.Position,
col: rl.Color,
angle: alias.Angle,
fade: color.fade.Fade = .{ .strength = 2 },
