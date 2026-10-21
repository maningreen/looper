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
const time = @import("time.zig");

const border = @import("border.zig");

const particles = @import("particle.zig");

const Player = @This();

comptime handle: Input.Handler = .{ .table = table },
comptime friction: alias.Friction = .{},
comptime player: PlayerFlag = .{},

color: raylib.Color = raylib.Color.yellow,
keymap: KeyMap = .{ .left = .s, .right = .f, .up = .e, .down = .d },
position: alias.Position = mangle.alias(alias.Position, raylib.Vector2.init(30, 30)),
velocity: alias.Velocity = mangle.alias(alias.Velocity, raylib.Vector2.zero()),
speed: alias.Speed = mangle.alias(alias.Speed, 1250),
cameraFollow: camera.Follow = mangle.alias(camera.Follow, true),

particleManager: ParticleManager = .{
    .time = .{ .elapsed = 0 },
},

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
    .accelerate = getAccel,
    .onAccelerate = spawnParticles,
};

fn getAccel(comptime T: type, player: *T, info: anytype) raylib.Vector2 {
    return player.keymap.getInput().scale(player.speed * info.delta);
}

fn spawnParticles(comptime T: type, player: *T, a: raylib.Vector2, info: anytype) Input.Handler.Error!void {
    const manager: *ParticleManager = &player.particleManager;
    var particle = manager.createParticle(info.extra.random) orelse return;
    particle.position.position = player.position;
    particle.color = particle.color.fade(0.8);
    const avgLen = particleRanges.averageRange(.length);
    const velocityScalar: f32 = a.lengthSqr() * avgLen / (particle.dimensions.side);
    const velocityAngle = std.math.atan2(-a.y, -a.x) + particleRanges.randomRange(particleRanges.getVelocityDeviation(a), info.extra.random);
    particle.velocity.velocity = .{ .x = @cos(velocityAngle) * velocityScalar, .y = @sin(velocityAngle) * velocityScalar };
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

    /// returns normalized vector of
    ///     x = -1 | 0 | 1
    ///     y = -1 | 0 | 1
    ///     but normalized
    fn getInput(self: KeyMap) raylib.Vector2 {
        return (raylib.Vector2{ .x = self.getHorizontalInput(), .y = self.getVerticalInput() }).normalize();
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

pub const PlayerFlag = struct {};

pub const particleRanges = struct {
    pub const theta = .{ 0.0, std.math.pi * 2 };
    pub const deltaTheta = .{ -std.math.pi, std.math.pi };
    pub const maxLifetime = .{ 2.0, 4.0 };
    pub const length = .{ 10, 20 };

    fn randomRange(range: struct { f32, f32 }, rand: std.Random) f32 {
        const scalar = rand.float(f32);
        return scalar * (range[1] - range[0]) + range[0];
    }
    fn randomFromRange(comptime value: std.meta.DeclEnum(@This()), rand: std.Random) f32 {
        const range = @field(particleRanges, @tagName(value));
        const scalar = rand.float(f32);
        return scalar * (range[1] - range[0]) + range[0];
    }

    fn averageRange(comptime value: std.meta.DeclEnum(@This())) comptime_float {
        const val = @field(particleRanges, @tagName(value));
        return (val[0] + val[1]) / 2;
    }

    fn getVelocityDeviation(accelaration: raylib.Vector2) struct { f32, f32 } {
        // this unit is in radians / (px / s^2)
        // It is also doubled.
        const scalar = 0.0125;
        const deviation = std.math.sqrt(1 - std.math.pow(f32, scalar * accelaration.length() - 1, 2));
        return .{ -deviation, deviation };
    }
};

pub const ParticleManager = struct {
    time: time.Elapsed,

    pub const timeToSpawn = 1 / 30;

    /// creates a particle at < 0, 0 > with velocity < 0, 0 >
    pub fn createParticle(self: *ParticleManager, random: std.Random) ?particles.Square {
        if (self.time.elapsed >= timeToSpawn) {
            self.time.elapsed -= timeToSpawn;

            return particles.Square{
                .color = .yellow,
                .dimensions = .{ .side = particleRanges.randomFromRange(.length, random) },
                .theta = .{ .theta = particleRanges.randomFromRange(.theta, random) },
                .deltaTheta = .{ .deltatheta = particleRanges.randomFromRange(.deltaTheta, random) },
                .maxLifetime = .{ .max = particleRanges.randomFromRange(.maxLifetime, random) },
            };
        } else return null;
    }
};
