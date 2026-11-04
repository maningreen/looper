const std = @import("std");
const Io = std.Io;

pub const mangle = @import("mangle");
pub const raylib = @import("raylib");
pub const raygui = @import("raygui");
pub const zlua = @import("zlua");

pub const defaultPixelLength = 4;

pixelLength: u16 = defaultPixelLength,
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
    .zoom = 1.0 / @as(comptime_float, defaultPixelLength),
},
random: std.Random,
lua: zlua.State,

renderTexture: raylib.RenderTexture2D,
shader: raylib.Shader,
paused: bool,

pub fn start(self: @This()) void {
    raylib.beginDrawing();

    self.renderTexture.begin();
    self.renderCamera.begin();

    raylib.clearBackground(.black);
}

pub fn end(self: @This()) void {
    self.renderCamera.end();
    self.renderTexture.end();

    self.shader.activate();
    self.camera.begin();

    const renderCount: struct { i32, i32 } = .{
        @divCeil(
            @as(i32, @ceil(self.windowDimensions.x / self.camera.zoom)),
            self.renderTexture.texture.width * self.pixelLength,
        ) + 2,
        @divCeil(
            @as(c_int, @ceil(self.windowDimensions.y / self.camera.zoom)),
            self.renderTexture.texture.height * self.pixelLength,
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
            .height = @as(f32, @floatFromInt(self.renderTexture.texture.width * self.pixelLength * renderCount[1])),
            .width = @as(f32, @floatFromInt(self.renderTexture.texture.height * self.pixelLength * renderCount[0])),
        },
        .{
            .x = @as(f32, @floatFromInt(self.renderTexture.texture.width * self.pixelLength * @divTrunc(renderCount[0], 2))),
            .y = @as(f32, @floatFromInt(self.renderTexture.texture.height * self.pixelLength * @divTrunc(renderCount[1], 2))),
        },
        0,
        .white,
    );

    self.camera.end();
    self.shader.deactivate();

    raylib.drawFPS(0, 0);

    raylib.endDrawing();
}
