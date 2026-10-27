const std = @import("std");

const mangle = @import("mangle");
const system = mangle.system;

const alias = @import("alias.zig");

pub const velocity = struct {
    pub const requirements = system.Signature.fromStruct(struct {
        p: alias.Position,
        v: alias.Velocity,
    });

    pub fn process(comptime T: type, value: *T, info: anytype) void {
        value.p = value.p.add(value.v.scale(info.delta));
    }
};

pub const friction = struct {
    pub const constant = 0.8;

    pub const requirements = system.Signature.fromStruct(struct {
        v: alias.Velocity,
        f: alias.Friction,
    });

    pub fn process(comptime T: type, value: *T, info: anytype) void {
        value.v = value.v.subtract(
            value.v.scale(constant * info.delta),
        );
    }
};

pub const rotation = struct {
    pub const Rotation = struct { theta: f32 };
    pub const AngularMomentum = struct { deltatheta: f32 };

    pub const system = struct {
        pub const requirements = mangle.system.Signature.fromStruct(struct {
            theta: Rotation,
            deltatheta: AngularMomentum,
        });

        pub fn process(comptime T: type, value: *T, info: anytype) void {
            value.theta.theta += value.deltatheta.deltatheta * info.delta;
        }
    };
};
