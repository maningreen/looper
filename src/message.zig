const std = @import("std");

/// writing these is most likely a huge waste of time.
/// TODO: write more
const messages: []const [:0]const u8 = &.{
    "Looper",
    "Looper: made with love",
    "Looper: made with anger",
    "Looper: with linux support!",
    "Looper: with many regrets",
    "Looper: not a single sprite",
    "Looper: still without sprites",
    "Looper: never had developer art",

    "Looper: please enjoy!",

    "Looper: terraria-minecraft joke",
    "Looper: splash-text stolen from terraria",
    "Looper: splash-text stolen from minecraft",
    "Looper: useless feature > useful feature",

    "Looper: an asteroids clone",

    "Looper-ing the rooms",
    "Looper: where are you? (and i'm so sorry)",
    "Looper: made by a creep, perhaps a weirdo",

    "Looper: made on nixos (btw)",
    "Looper: i used to use arch (btw)",

    "Looper: written in zig",
    "Looper: using raylib",
    // ": and lua support!",

    "Looper: consider modding!",

    "Looper: 1. I",
    "Looper: 2. found",
    "Looper: 3. these",
    "Looper: 4. dumb",
    "Looper: 5. texts",
    "Looper: 6. and",
    "Looper: 7. all",
    "Looper: 8. I",
    "Looper: 9. got",
    "Looper: 10. was",
    "Looper: 11. this",
    "Looper: 12. lousy",
    "Looper: 13. message",

    "Looper: You can edit the palette in ./resources/shaders",

    "Looper: If this message is in the final build make fun of me",
    "Looper: time was spent on these",

    "Looper: I can code, but I can't spell",
    "Looper: If you mod multiplayer I'll give you a dollar",

    "Looper: buzzword-buzzword-buzzword",
    "Looper: insert witty-self-referential joke",

    "Looper: better than geometry class!",
    "Looper: there's a secret splash-text in the binary!",
};

pub const secrets: []const [:0]const u8 = &.{
    "Looper: the secret message :), there's more!\n, did you use `strings` for this?\nif you did that'd be cool",
};

comptime {
    _ = &secrets;
}

pub inline fn getRandom(r: std.Random) [:0]const u8 {
    return messages[r.int(usize) % messages.len];
}
