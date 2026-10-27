const Elapsed = @import("../time.zig").Elapsed;
const mangle = @import("mangle");
const render = @import("../render.zig");

pub const Manager = struct {
    time: Elapsed = .{ .elapsed = 0 },
    rate: f32 = 1,
    count: u32,

    /// returns [0..count]
    pub fn getLevel(self: Manager) f32 {
        return @min(self.count, self.rate * self.time.elapsed);
    }

    /// will only return [0..count]
    pub fn getCount(self: Manager) u2 {
        return @trunc(@min(self.count, self.rate * self.time.elapsed));
    }

    pub fn canUse(self: Manager) bool {
        return self.time.elapsed >= 1;
    }

    pub fn use(self: *Manager) bool {
        self.time.elapsed = @min(self.time.elapsed, @as(f32, @floatFromInt(self.count)));
        if (self.time.elapsed / self.rate >= 1) {
            self.time.elapsed -= 1.0 / self.rate;
            return true;
        }
        return false;
    }

    /// returns [0..1], based off of the proportion of time to count.
    pub fn getScalar(self: Manager) f32 {
        return @min(1, self.rate * self.time.elapsed / (@as(f32, @floatFromInt(self.count))));
    }
};
