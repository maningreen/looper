const std = @import("std");
const Io = std.Io;

pub const mangle = @import("mangle");
pub const raylib = @import("raylib");
pub const raygui = @import("raygui");

const Input = @import("input.zig");
const render = @import("render.zig");
const alias = @import("alias.zig");
const physics = @import("physics.zig");
const camera = @import("camera.zig");

pub const border = @import("border.zig");

const particles = @import("particle.zig");

pub const PlayerFlag = struct {};

const Player = @This();

comptime handle: Input.Handler = .{ .table = table },
comptime friction: alias.Friction = .{},
comptime color: raylib.Color = raylib.Color.yellow,
comptime player: PlayerFlag = .{},

keymap: KeyMap = .{ .left = .s, .right = .f, .up = .e, .down = .d },
position: alias.Position = mangle.alias(alias.Position, raylib.Vector2.init(30, 30)),
velocity: alias.Velocity = mangle.alias(alias.Velocity, raylib.Vector2.zero()),
speed: alias.Speed = mangle.alias(alias.Speed, 1250),
cameraFollow: camera.Follow = mangle.alias(camera.Follow, true),

pub const default = Player{};

pub fn init(gpa: std.mem.Allocator, io: std.Io) !Player {
    const keymap = KeyMap.fromFile(gpa, io, null) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => KeyMap{},
    };
    return Player{
        .keymap = keymap,
    };
}

const table = Input.Handler.VTable{
    .getVelocity = getVelocity,
    .onAccelerate = spawnParticles,
};

fn getVelocity(comptime T: type, player: *T, info: anytype) raylib.Vector2 {
    const deltaV = player.keymap.getInput().scale(player.speed * info.delta);
    return player.velocity.add(deltaV);
}

fn spawnParticles(comptime T: type, player: *T, info: anytype) Input.Handler.Error!void {
    const vel: raylib.Vector2 = player.velocity;
    const particle = particles.Square{
        .color = raylib.Color.yellow.fade(0.8),
        .dimensions = .{ .side = 5 },
        .velocity = mangle.alias(alias.Velocity, vel.negate()),
        .position = mangle.alias(alias.Position, player.position),
        .maxLifetime = .{ .max = 5}
    };
    info.appendDeferred(particle) catch return Input.Handler.Error.AccelerateError;
}

const KeyMap = struct {
    pub const parse = struct {
        pub const localPath: []const u8 = "resources/keymap.zig.zon";
        /// 1 megabyte.
        pub const maximum: usize = 1e6;
    };

    const Key = raylib.KeyboardKey;

    left: Key = .a,
    right: Key = .d,
    up: Key = .w,
    down: Key = .s,

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

    fn fromFile(gpa: std.mem.Allocator, io: std.Io, path: ?[]const u8) !KeyMap {
        const file = try std.Io.Dir.cwd().openFile(io, path orelse parse.localPath, .{ .mode = .read_only });
        defer file.close(io);

        var readBuf: [1028]u8 = undefined;
        var reader = file.reader(io, readBuf[0..]);

        const source = try reader.interface.allocRemainingAlignedSentinel(gpa, .limited(parse.maximum), .@"1", 0);
        defer gpa.free(source);

        var diagnostics = std.zon.parse.Diagnostics{
            .errors = &.{},
        };
        const parsed = std.zon.parse.fromSliceNoAlloc(
            KeyMap,
            .{
                .arena = .failing,
                .diagnostics = &diagnostics,
                .gpa = gpa,
                .ignore_unknown_fields = true,
                .source = source,
            },
        );
        if (diagnostics.errors.len > 0) {
            diagnostics.log(path orelse parse.localPath);
        }
        return parsed;
    }
};
