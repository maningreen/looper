const std = @import("std");

/// writing these is most likely a huge waste of time.
/// TODO: write more
const messages: []const []const u8 = &.{
    "",
    ": made with love",
    ": made with anger",
    ": with linux support!",
    ": with many regrets",
    ": not a single sprite",
    ": still without sprites",
    ": never had developer art",

    ": please enjoy!",

    ": splash-text stolen from terraria",
    ": useless feature > useful feature",

    ": an asteroids clone",

    "-ing the rooms",
    ": where are you? (and i'm so sorry)",
    ": made by a creep, perhaps a weirdo",

    ": made on nixos (btw)",
    ": i used to use arch (btw)",

    ": written in zig",
    ": using raylib",
    // ": and lua support!",
    ": mangle.zig on github",

    ": consider modding!",

    ": 1. I",
    ": 2. found",
    ": 3. these",
    ": 4. dumb",
    ": 5. texts",
    ": 6. and",
    ": 7. all",
    ": 8. I",
    ": 9. got",
    ": 10. was",
    ": 11. this",
    ": 12. lousy",
    ": 13. message",

    ": You can edit the palette in ./resources/shaders",

    ": If this message is in the final build make fun of me",
    ": time was spent on these",

    ": I can code, but I can't spell",
    ": If you mod multiplayer I'll give you a dollar",

    ": terraria-minecraft joke",

    ": buzzword-buzzword-buzzword",
    ": insert witty-self-referential joke",

    ": better than geometry class!",
};

pub inline fn getRandom(r: std.Random) []const u8 {
    return messages[r.int(usize) % messages.len];
}
