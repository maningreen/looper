const std = @import("std");

const mangle = @import("mangle");
const rl = @import("raylib");

const alias = @import("alias.zig");
const Player = @import("player.zig");
const border = @import("border.zig");
const physics = @import("physics.zig");

pub const circle = struct {
    pub const requirements = mangle.system.Signature{
        .fields = &.{
            .{ .name = "color", .schema = .{ .simple = rl.Color } },
            .{ .name = "radius", .schema = .{ .simple = alias.Radius } },
            .{ .name = "pos", .schema = .{ .simple = alias.Position } },
        },
    };
    pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) void {
        switch (@TypeOf(event)) {
            alias.Render => draw(value),
            else => {},
        }
    }

    fn draw(value: anytype) void {
        rl.drawCircleV(value.pos, value.radius, value.color);
    }
};

pub const square = struct {
    pub const requirements = mangle.system.Signature{
        .fields = &.{
            .{ .name = "position", .schema = .{ .simple = alias.Position } },
            .{ .name = "length", .schema = .{ .simple = alias.SquareDimensions } },
            .{ .name = "color", .schema = .{ .simple = rl.Color } },
            .{ .name = "rot", .schema = .{ .simple = physics.rotation.Rotation }, .status = .optional },
        },
    };

    pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) void {
        switch (@TypeOf(event)) {
            alias.Render => draw(value.*),
            else => {},
        }
    }

    fn draw(value: anytype) void {
        const T = @TypeOf(value);
        if (@hasField(T, "rot")) {
            rl.drawRectanglePro(
                .{
                    .x = value.position.x,
                    .y = value.position.y,
                    .height = value.length.side,
                    .width = value.length.side,
                },
                (rl.Vector2{ .x = value.length.side, .y = value.length.side }).scale(0.5),
                value.rot.theta * std.math.deg_per_rad,
                value.color,
            );
        } else {
            rl.drawRectanglePro(
                .{
                    .x = value.position.x,
                    .y = value.position.y,
                    .height = value.length.side,
                    .width = value.length.side,
                },
                (rl.Vector2{ .x = value.length.side, .y = value.length.side }).scale(0.5),
                0,
                value.color,
            );
        }
    }
};

pub const player = struct {
    const deltaTheta = std.math.pi * 2.0 / 3.0;
    const size = 50;

    pub const RenderFlag = struct {};

    pub const requirements = mangle.system.Signature.fromStruct(struct {
        flag: RenderFlag,
        position: alias.Position,
        color: rl.Color,
    });

    pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) void {
        switch (@TypeOf(event)) {
            alias.Render => drawPlayer(value, info),
            else => {},
        }
    }

    fn drawPlayer(value: anytype, info: anytype) void {
        const mousePosition = info.extra.mousePosition;

        const diff: rl.Vector2 = mousePosition.subtract(value.position);
        const farVetrex = diff.normalize().scale(size).add(value.position);

        const theta = std.math.atan2(diff.y, diff.x);
        const length = 40;

        const drawA = theta + deltaTheta;
        const sideVertexA = rl.Vector2.init(length * std.math.cos(drawA), length * std.math.sin(drawA));
        rl.drawTriangle(farVetrex, value.position, sideVertexA.add(value.position), value.color);

        const drawB = theta - deltaTheta;
        const sideVertexB = rl.Vector2.init(length * std.math.cos(drawB), length * std.math.sin(drawB));
        rl.drawTriangle(value.position, farVetrex, sideVertexB.add(value.position), value.color);

        rl.drawCircleV(value.position, 5, .white);
    }
};
