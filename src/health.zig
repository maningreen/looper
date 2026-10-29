const std = @import("std");
const mangle = @import("mangle");

const HealthManager = @This();

health: f32,
maxHealth: f32,

pub const system = struct {
    pub const Extra = struct {
        onDeath: ?fn (comptime T: type, value: anytype, info: anytype) Error!void = null,
    };

    pub const Error = error{DeathError};

    pub const requirements = mangle.system.Signature{
        .fields = &.{
            .{ .name = "hm", .schema = .{ .simple = HealthManager } },
            .{ .name = "extra", .schema = .{ .simple = Extra }, .status = .optional },
        },
    };

    pub fn process(comptime T: type, value: *T, info: anytype) !void {
        if (value.hm.isDead()) {
            if (@hasField(T, "extra"))
                if (value.extra.onDeath) |f| 
                    try f(T, value, info);
            try info.dropDeferred(value);
        }
    }
};

pub fn init(max: f32) HealthManager {
    return .{
        .health = max,
        .maxHealth = max,
    };
}

pub fn damage(hm: HealthManager, hp: f32) HealthManager {
    return .{
        .maxHealth = hm.maxHealth,
        .health = hm.health - hp,
    };
}

pub fn heal(hm: HealthManager, hp: f32) HealthManager {
    return .{
        .maxHealth = hp.maxHealth,
        .health = @min(hp.maxHealth, hm.health + hp),
    };
}

pub fn isDead(hm: HealthManager) bool {
    return hm.health <= 0;
}

/// returns from [0, 1] the health relative to max
pub fn getScalar(hm: HealthManager) f32 {
    return hm.health / hm.maxHealth;
}
