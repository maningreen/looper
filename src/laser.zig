const std = @import("std");
const alias = @import("alias.zig");
const mangle = @import("mangle");
const rl = @import("raylib");
const border = @import("border.zig");

const Laser = @This();

start: alias.Position,
angle: f32,
length: f32,
color: rl.Color,

thickness: f32,

pub const system = struct {
    pub const render = struct {
        pub const requirements = mangle.system.Signature.fromStruct(struct {
            laser: Laser,
        });

        pub fn receive(comptime T: type, value: *T, event: anytype, _: anytype) void {
            switch (@TypeOf(event)) {
                alias.Render => value.laser.draw(),
                else => {},
            }
        }
    };
};

/// iterates over instances of looping.
/// Asserted las.angle [0, 2 * pi]
pub const Iterator = struct {
    laser: ?Laser,

    pub fn next(self: *Iterator) ?Laser {
        const las = &(self.laser orelse return null);
        const offset = las.localOffset();
        // there are two conditions (x|y) < 0 and (x|y) > border.length
        // (x|y)(t: [0, 1]) = start + offset * t
        // so if (x|y) <= 0
        //     -start / offset = t
        // so but if (x|y) > border.length
        //     t == border.length - start
        //          ---------------------
        //                  offset
        // which can be generalized to
        // t == (target) - start
        //      ----------------
        //            offset
        // and if T \elem [0, 1], then it hits. otherwise, it don't
        // Then plugging T -> p(T) will return the position of the collision (local)
        // It also happens that T * las.length == the length of the laser before breaking.
        //
        // Calcluating whether or not x is negative or note keeps us from doing both equations

        const negX = offset.x < 0;
        const negY = offset.y < 0;

        const targetX = if (negX) 0 else border.length;
        const targetY = if (negY) 0 else border.length;

        const hitTs: @Vector(2, f32) = .{
            (targetX - las.start.position.x) / offset.x,
            (targetY - las.start.position.y) / offset.y,
        };
        const min: @Vector(2, f32) = @splat(0);
        const max: @Vector(2, f32) = @splat(1);
        const hits = @reduce(.Or, hitTs >= min) and @reduce(.Or, hitTs <= max);
        if (!hits) {
            const l = las.*;
            self.laser = null;
            return l;
        }
        const hitT = @reduce(
            .Min,
            @select(
                f32,
                hitTs >= min,
                hitTs,
                @select(
                    f32,
                    hitTs <= max,
                    hitTs,
                    @as(@Vector(2, f32), @splat(max[0] + 1)),
                ),
            ),
        );
        const hitLength = hitT * las.length;
        const sub = Laser{
            .length = hitLength,
            .angle = las.angle,
            .color = las.color,
            .start = las.start,
            .thickness = las.thickness,
        };
        las.length -= hitLength;
        las.start.position = border.wrap(las.start.position.add(sub.localOffset()));
        return sub;
    }
};

pub fn init(a: rl.Vector2, b: rl.Vector2, color: rl.Color, thickness: f32) Laser {
    const diff = b.subtract(a);
    const mag = diff.length();
    const theta = std.math.atan2(diff.y / mag, diff.x / mag);

    return .{
        .start = .{ .position = a },
        .angle = theta,
        .length = mag,
        .color = color,
        .thickness = thickness,
    };
}

pub fn draw(self: Laser) void {
    var it = self.iterate();
    while (it.next()) |sub|
        rl.drawLineEx(sub.start.position, sub.endPos(), sub.thickness, sub.color);
}

pub fn endPos(self: Laser) rl.Vector2 {
    const offset = rl.Vector2{
        .x = self.length * @cos(self.angle),
        .y = self.length * @sin(self.angle),
    };
    return offset.add(self.start.position);
}

pub fn localOffset(self: Laser) rl.Vector2 {
    return .{
        .x = self.length * @cos(self.angle),
        .y = self.length * @sin(self.angle),
    };
}

pub fn iterate(self: Laser) Iterator {
    return .{ .laser = self };
}

pub fn collidesWrap(self: Laser, pos: rl.Vector2, rad: f32) bool {
    var it = self.iterate();
    while (it.next()) |las| {
        if (las.collides(pos, rad)) return true;
    }
    return false;
}

/// returns whether or not a circle with position pos and radius rad falls onto the laser
/// This does not wrap the laser or the circle.
pub fn collides(self: Laser, pos: rl.Vector2, rad: f32) bool {
    // transform `pos` into local coordinates
    const transform: struct { rl.Vector2, rl.Vector2 } = .{
        rl.Vector2{ .x = @cos(self.angle), .y = @sin(self.angle) },
        rl.Vector2{ .x = -@sin(self.angle), .y = @cos(self.angle) },
    };

    const offset = pos.subtract(self.start.position);

    // (i'm learning linear algebra give me a moment)
    // i = [ cos(theta) ] j = [ sin(theta) ]
    //     [ sin(theta) ]     [ cos(theta) ]
    // i(x) + j(y)

    const local: rl.Vector2 = transform[0].scale(offset.x).add(transform[1].scale(offset.y));

    rl.drawCircleV(border.wrap(local), 50, .blue);
    _ = &rad;

    const range = .{ 0, self.length };

    const closest = std.math.clamp(local.x, range[0], range[1]);

    const distance = local.distanceSqr(.{ .x = closest, .y = 0 });
    return distance <= rad * rad;
}
