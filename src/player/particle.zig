const std = @import("std");
const rl = @import("raylib");

const accelerate = @import("../accelerate.zig");
const input = @import("../input.zig");
const render = @import("../render.zig");
const alias = @import("../alias.zig");
const physics = @import("../physics.zig");
const camera = @import("../camera.zig");

const Elapsed = @import("../time.zig").Elapsed;
const VectorMap = @import("../player/vectormap.zig");

const particles = @import("../particle.zig");

pub const Manager = struct {
    time: Elapsed,
    shouldSpawn: bool = false,

    pub const timeToSpawn = 1.0 / 60.0;

    /// creates a particle at < 0, 0 > with velocity < 0, 0 >
    pub fn createParticle(self: *Manager, random: std.Random) ?particles.Square {
        if (self.time.elapsed >= timeToSpawn) {
            self.time.elapsed = 0;

            return particles.Square{
                .color = .yellow,
                .dimensions = .{ .side = ranges.randomFromRange(.length, random) },
                .theta = .{ .theta = ranges.randomFromRange(.theta, random) },
                .deltaTheta = .{ .deltatheta = ranges.randomFromRange(.deltaTheta, random) },
                .maxLifetime = .{ .max = ranges.randomFromRange(.maxLifetime, random) },
            };
        } else return null;
    }
};

pub const ranges = struct {
    pub const theta = .{ 0.0, std.math.pi * 2 };
    pub const deltaTheta = .{ -std.math.pi, std.math.pi };
    pub const maxLifetime = .{ 2.0, 4.0 };
    pub const length = .{ 10, 20 };

    pub fn randomRange(range: struct { f32, f32 }, rand: std.Random) f32 {
        const scalar = rand.float(f32);
        return scalar * (range[1] - range[0]) + range[0];
    }

    pub fn randomFromRange(comptime value: std.meta.DeclEnum(@This()), rand: std.Random) f32 {
        const range = @field(ranges, @tagName(value));
        const scalar = rand.float(f32);
        return scalar * (range[1] - range[0]) + range[0];
    }

    pub fn averageRange(comptime value: std.meta.DeclEnum(@This())) comptime_float {
        const val = @field(ranges, @tagName(value));
        return (val[0] + val[1]) / 2;
    }

    pub fn getVelocityDeviation(v: f32) struct { f32, f32 } {
        // this unit is in radians / (px^2 / s^2)
        // It is also doubled.
        const scalar = 2500 * 2500;
        const deviation = (scalar / (v * v)) * (std.math.pi / 12.0);
        return .{ -deviation, deviation };
    }
};
