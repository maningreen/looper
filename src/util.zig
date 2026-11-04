const std = @import("std");
const rl = @import("raylib");

pub fn checkCollisionLineCircle(start: rl.Vector2, end: rl.Vector2, center: rl.Vector2, radius: f32) bool {
    // transform `pos` into local coordinates
    // cah
    // x / mag
    const diff = end.subtract(start);
    const mag = diff.length();

    const transform = .{
        .i = rl.Vector2{ .x = diff.x / mag, .y = diff.y / mag },
        .j = rl.Vector2{ .x = -diff.y / mag, .y = diff.x / mag },
    };

    const offset = center.subtract(start);

    // (i'm learning linear algebra give me a moment)
    // i = [ cos(theta) ] j = [ -sin(theta) ]
    //     [ sin(theta) ]     [ cos(theta) ]
    // i(x) + j(y)

    const iPart = transform.i.scale(offset.x);
    const jPart = transform.j.scale(offset.y);
    const local: rl.Vector2 = iPart.add(jPart);

    const range = .{ 0, mag };

    const closest = std.math.clamp(local.x, range[0], range[1]);

    const distance = local.distanceSqr(.{ .x = closest, .y = 0 });

    return distance <= radius * radius;
}

/// Implementation heavily inspired from [here](http://jeffreythompson.org/collision-detection/poly-point.php)
pub fn checkCollisionCirclePoly(center: rl.Vector2, radius: f32, points: []rl.Vector2) bool {
    var collides: bool = false;
    var maxTau: f32 = 0;

    for (0..points.len) |i| {
        const j = @mod(i + 1, points.len);
        const current = points[i];
        const next = points[j];

        const betweenY = (@abs(current.y - center.y) <= radius) != (@abs(next.y - current.y) <= radius);
        // todo: research this
        const jordanTau =
            (next.x - current.x) * (center.y - current.y) / (next.y - current.y) + current.x;
        maxTau = @max(maxTau, @abs(jordanTau - current.x));
        if (center.x < jordanTau and betweenY)
            collides = !collides;
    }
    std.log.debug("tau: {d}", .{maxTau});
    return collides;
}
