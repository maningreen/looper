const std = @import("std");
const mangle = @import("mangle");
const rl = @import("raylib");

pub const fade = struct {
    pub const Fade = struct {
        strength: f32,
    };

    pub const system = struct {
        pub const requirements = mangle.system.Signature.fromStruct(struct {
            col: rl.Color,
            params: Fade,
        });

        pub fn process(comptime T: type, value: *T, info: anytype) void {
            const params: Fade = value.params;
            const col: *rl.Color = &value.col;
            col.a = col.a -| col.fade(params.strength * info.delta).a;
        }
    };
};

pub const transparent = struct {
    pub const Transparent = struct {};

    pub const system = struct {
        pub const requirements = mangle.system.Signature.fromStruct(struct {
            col: rl.Color,
            __ignore__: Transparent,
        });

        pub fn process(comptime T: type, value: *T, info: anytype) !void {
            if (value.col.a < 5) try info.dropDeferred(value);
        }
    };
};
