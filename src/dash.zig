const std = @import("std");
const mangle = @import("mangle");
const rl = @import("raylib");

const alias = @import("alias.zig");
const time = @import("time.zig");

pub const Manager = struct {
    time: time.Elapsed = .{ .elapsed = 0 },
    maxTime: f32 = 0.5,
    isDashing: bool = false,
    speed: alias.Speed = .{ .speed = 2000 },

    pub fn beginDash(self: *Manager) void {
        if (!self.isDashing) {
            self.time.elapsed = 0;
        }
        self.isDashing = true;
    }

    pub const HookTable = struct {
        onEnd: fn (comptime T: type, value: anytype, info: anytype) Error!void,

        pub const Error = error{
            HookError,
        };
    };
};

pub const system = struct {
    pub const requirements = mangle.system.Signature{
        .fields = &.{
            .{ .name = "manager", .schema = .{ .simple = Manager } },
            .{ .name = "velocity", .schema = .{ .simple = alias.Velocity } },
            .{ .name = "table", .schema = .{ .simple = Manager.HookTable }, .status = .optional },
        },
    };

    pub fn process(comptime T: type, value: *T, info: anytype) void {
        const manager: *Manager = &value.manager;
        const velocity: *rl.Vector2 = &value.velocity;
        if (manager.isDashing) {
            velocity.* = velocity.normalize().scale(manager.speed.speed);
            manager.isDashing = manager.time.elapsed < manager.maxTime;
            if (comptime @hasField(T, "table") and @FieldType(T, "table") == Manager.HookTable)
                if (!manager.isDashing)
                    try value.table.onEnd(T, value, info);
        }
    }
};
