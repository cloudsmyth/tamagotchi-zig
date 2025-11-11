const std = @import("std");
const Pet = @import("pet.zig").Pet;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    //const allocator = gpa.allocator();

    var pet = Pet.init();

    std.debug.print("Your pet has hatched!", .{});

    while (pet.alive) {
        pet.update();

        std.debug.print("\n--- Status ---\n", .{});
        std.debug.print("Hunger: {d}/100\n", .{pet.hunger});
        std.debug.print("Happiness: {d}/100\n", .{pet.happiness});
        std.debug.print("Age: {d}s\n", .{pet.age_seconds});

        std.debug.print("[F]eed [P]lay [Q]uit\n", .{});

        var stdin_buffer: [1024]u8 = undefined;
        var stdin: std.fs.File = std.fs.File.stdin();
        var stdin_reader: std.fs.File.Reader = stdin.reader(&stdin_buffer);
        const stdin_ioreader: *std.Io.Reader = &stdin_reader.interface;

        if (stdin_ioreader.takeDelimiterExclusive('\n')) |input| {
            const trimmed = std.mem.trim(u8, input, &std.ascii.whitespace);
            if (trimmed.len > 0) {
                switch (trimmed[0]) {
                    'f', 'F' => {
                        pet.feed();
                        std.debug.print("Pet has eaten some food!\n", .{});
                    },
                    'p', 'P' => {
                        pet.play();
                        std.debug.print("Pet has played and is feeling happier!\n", .{});
                    },
                    'q', 'Q' => break,
                    else => std.debug.print("Please choose a valid command\n", .{}),
                }
            }
        } else |err| switch (err) {
            error.EndOfStream,
            error.StreamTooLong,
            error.ReadFailed,
            => |e| return e,
        }
    }

    std.debug.print("Your pet has expired.... X.X\n", .{});
}
