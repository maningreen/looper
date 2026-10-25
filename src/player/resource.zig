const Elapsed = @import("../time.zig").Elapsed;
const mangle = @import("mangle");

const Manager = struct {
    time: Elapsed = .{ .elapsed = 0 },
    offset: f32 = 10,

    /// will only return [0..3]
    fn getCount(self: Manager) u2 {
        return @trunc(@min(3, self.time.elapsed));
    }

    fn canUse(self: Manager) bool {
        return self.time.elapsed >= 1;
    }

    fn use(self: *Manager) bool {
        if (self.time.elapsed >= 1) {
            self.time.elapsed -= 1;
            return true;
        }
        return false;
    }
};
