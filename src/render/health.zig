const std = @import("std");
const rl = @import("raylib");
const mangle = @import("mangle");
const alias = @import("../alias.zig");
const HealthMagnager = @import("../health.zig");

pub const Flag = struct {
    fill: rl.Color = .red,
    empty: rl.Color = .gray,

    offset: rl.Rectangle = .{ .x = 0, .y = 0, .height = 0, .width = 0 },
};

pub const system = struct {
    pub const requirements = mangle.system.Signature.fromStruct(struct {
        pos: alias.Position,
        flag: Flag,
        hm: HealthMagnager,
    });

    pub fn receive(comptime T: type, value: *T, event: anytype, info: anytype) void {
        switch (@TypeOf(event)) {
            alias.Render => render(T, value, info),
            else => {},
        }
    }

    pub fn render(comptime T: type, value: *T, _: anytype) void {
        const proportion = value.hm.getScalar();
        const flag: Flag = value.flag;

        std.debug.assert(proportion <= 1 and proportion >= 0);

        const health = rl.Rectangle{
            .x = flag.offset.x + value.pos.x,
            .y = flag.offset.y + value.pos.y,
            .width = flag.offset.width * proportion,
            .height = flag.offset.height,
        };
        const damage = rl.Rectangle{
            .x = health.x + health.width,
            .y = health.y,
            .height = flag.offset.height,
            .width = flag.offset.width - health.width,
        };
        rl.drawRectangleRec(health, flag.fill);
        rl.drawRectangleRec(damage, flag.empty);
    }
};
