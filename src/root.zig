const std = @import("std");
const Io = std.Io;

pub const mangle = @import("mangle");
pub const raylib = @import("raylib");
pub const raygui = @import("raygui");

pub const input = @import("input.zig");
pub const accelerate = @import("accelerate.zig");
pub const render = @import("render.zig");
pub const alias = @import("alias.zig");
pub const physics = @import("physics.zig");
pub const border = @import("border.zig");
pub const time = @import("time.zig");
pub const color = @import("color.zig");
pub const dash = @import("dash.zig");

pub const Player = @import("player.zig");
pub const particle = @import("particle.zig");

pub const camera = @import("camera.zig");

pub const Registry = mangle.Registry(
    &.{
        Player,
        particle.Square,
    },
    &.{
        input.system,

        accelerate.system,

        dash.system,

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

const pixelLength = 10;

pub const Extra = struct {
    pixelLength: u32 = 10,
    mousePosition: raylib.Vector2 = .zero(),
    windowDimensions: raylib.Vector2 = .zero(),
    camera: raylib.Camera2D = .{
        .offset = .zero(),
        .rotation = 0,
        .target = .zero(),
        .zoom = 1,
    },
    renderCamera: raylib.Camera2D = .{
        .rotation = 0,
        .target = .zero(),
        .offset = .zero(),
        .zoom = 1.0 / @as(comptime_float, pixelLength),
    },
    random: std.Random,

    renderTexture: raylib.RenderTexture2D,
    shader: raylib.Shader,

    pub fn start(self: Extra) void {
        raylib.beginDrawing();

        self.renderTexture.begin();
        self.renderCamera.begin();

        raylib.clearBackground(.black);
    }

    pub fn end(self: Extra) void {
        self.renderCamera.end();
        self.renderTexture.end();

        self.shader.activate();
        self.camera.begin();

        const renderCount: struct { i32, i32 } = .{
            @divCeil(
                @as(c_int, @ceil(self.windowDimensions.x / self.camera.zoom)),
                self.renderTexture.texture.width * pixelLength,
            ) + 2,
            @divCeil(
                @as(c_int, @ceil(self.windowDimensions.y / self.camera.zoom)),
                self.renderTexture.texture.height * pixelLength,
            ) + 2,
        };

        self.renderTexture.texture.drawPro(
            .{
                .x = 0,
                .y = 0,
                .height = @floatFromInt(-self.renderTexture.texture.height * renderCount[1]),
                .width = @floatFromInt(self.renderTexture.texture.width * renderCount[0]),
            },
            .{
                .x = 0,
                .y = 0,
                .height = @as(f32, @floatFromInt(self.renderTexture.texture.width * pixelLength * renderCount[1])),
                .width = @as(f32, @floatFromInt(self.renderTexture.texture.height * pixelLength * renderCount[0])),
            },
            .{
                .x = @as(f32, @floatFromInt(self.renderTexture.texture.width * pixelLength * @divTrunc(renderCount[0], 2))),
                .y = @as(f32, @floatFromInt(self.renderTexture.texture.height * pixelLength * @divTrunc(renderCount[1], 2))),
            },
            0,
            .white,
        );

        self.camera.end();
        self.shader.deactivate();
        raylib.endDrawing();
    }
};
