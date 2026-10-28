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
    pub const size = 40;
    pub const body = struct {
        const deltaTheta = std.math.pi * 2.0 / 3.0;

        pub const RenderFlag = struct {
            dot: bool = true,
        };

        pub const requirements = mangle.system.Signature{ .fields = &.{
            .{ .name = "flag", .schema = .{ .simple = RenderFlag } },
            .{ .name = "position", .schema = .{ .simple = alias.Position } },
            .{ .name = "color", .schema = .{ .simple = rl.Color } },
            .{ .name = "angle", .schema = .{ .simple = alias.Angle }, .status = .optional },
        } };

        pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) void {
            switch (@TypeOf(event)) {
                alias.Render => drawPlayer(value, info),
                else => {},
            }
        }

        fn drawPlayer(value: anytype, info: anytype) void {
            // const mousePosition = info.extra.mousePosition;
            // const diff: rl.Vector2 = mousePosition.subtract(value.position);

            const theta =
                if (@hasField(@TypeOf(value.*), "angle"))
                    value.angle
                else
                    std.math.atan2(
                        info.extra.mousePosition.y - value.position.y,
                        info.extra.mousePosition.x - value.position.x,
                    );

            const farVetrex =
                if (@hasField(@TypeOf(value.*), "angle"))
                    (rl.Vector2{ .x = @cos(theta) * size, .y = @sin(theta) * size }).add(value.position)
                else
                    info.extra.mousePosition.subtract(value.position).normalize().scale(size).add(value.position);

            const drawA = theta + deltaTheta;
            const sideVertexA = rl.Vector2.init(size * std.math.cos(drawA), size * std.math.sin(drawA));
            rl.drawTriangle(farVetrex, value.position, sideVertexA.add(value.position), value.color);

            const drawB = theta - deltaTheta;
            const sideVertexB = rl.Vector2.init(size * std.math.cos(drawB), size * std.math.sin(drawB));
            rl.drawTriangle(value.position, farVetrex, sideVertexB.add(value.position), value.color);

            if (value.flag.dot)
                rl.drawCircleV(value.position, 5, .white);
        }
    };

    pub const resources = struct {
        pub const blockSize = 10;
        pub const dimensions: rl.Vector2 = .{ .x = 10, .y = 2 * size };
        pub const relativeOffset: rl.Vector2 = .{ .x = size * 1.5, .y = -size * 1 };

        pub const requirements = mangle.system.Signature.fromStruct(struct {
            resource: Player.Resource,
            color: rl.Color,
            position: alias.Position,
        });

        pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) void {
            switch (@TypeOf(event)) {
                alias.Render => draw(value, info),
                else => {},
            }
        }

        fn draw(value: anytype, _: anytype) void {
            const resource: *Player.Resource = &value.resource;
            const position: rl.Vector2 = value.position;
            const blockingOffset = size * 2 / @as(f32, @floatFromInt(resource.count));
            const scalar = resource.getScalar();
            const drawPosition = border.wrap(position.add(relativeOffset));
            const drawRect: rl.Rectangle = .{
                .x = drawPosition.x,
                .y = drawPosition.y,
                .height = dimensions.y * scalar,
                .width = dimensions.x,
            };
            rl.drawRectangleRec(drawRect, value.color);
            for (1..resource.count + 1) |i| {
                rl.drawRectangleV(
                    drawPosition.add(.{
                        .x = 0,
                        .y = @as(f32, @floatFromInt(i)) * blockingOffset,
                    }),
                    .{ .x = blockSize, .y = blockSize },
                    rl.Color.fade(.black, 0.6),
                );
            }
        }
    };
};
