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
        if (self.laser) |*las| {
            const offset = las.localOffset();
            const end: rl.Vector2 = las.start.position.add(offset);
            if (!border.wrap(end).equals(end)) {
                std.log.debug("wraps", .{});
                // step 1: get *where* it wraps

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

                const hitTs = .{
                    (targetX - las.start.position.x) / offset.x,
                    (targetY - las.start.position.y) / offset.y,
                };
                const hitT = @min(hitTs[0], hitTs[1]);
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
                std.log.debug("{d}", .{hitLength});
                return sub;
            } else {
                const laser = self.laser;
                self.laser = null;
                return laser;
            }
        }
        return null;
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
