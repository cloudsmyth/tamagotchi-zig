const std = @import("std");
const vaxis = @import("vaxis");
const Pet = @import("pet.zig").Pet;

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var pet = Pet.init();
    var mutex = std.Thread.Mutex{};

    const update_thread = try std.Thread.spawn(.{}, gameLoop, .{ &pet, &mutex });
    defer update_thread.join();

    var tty_buf: [4096]u8 = undefined;
    var tty = try vaxis.Tty.init(&tty_buf);
    defer tty.deinit();

    var vx = try vaxis.init(alloc, .{});
    defer vx.deinit(alloc, tty.writer());

    var loop: vaxis.Loop(Event) = .{ .tty = &tty, .vaxis = &vx };
    try loop.init();
    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(tty.writer());
    try vx.queryTerminal(tty.writer(), 1 * std.time.ns_per_s);

    try render(&vx, &pet, &mutex);
    try vx.render(tty.writer());

    while (pet.alive) {
        const event = loop.nextEvent();

        switch (event) {
            .key_press => |key| {
                mutex.lock();
                defer mutex.unlock();

                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    pet.alive = false;
                    break;
                } else if (key.matches('f', .{})) {
                    pet.feed();
                } else if (key.matches('p', .{})) {
                    pet.play();
                }
            },
            .winsize => |ws| {
                try vx.resize(alloc, tty.writer(), ws);
            },
        }

        try render(&vx, &pet, &mutex);
        try vx.render(tty.writer());
    }
}

fn gameLoop(pet: *Pet, mutex: *std.Thread.Mutex) void {
    while (true) {
        std.Thread.sleep(std.time.ns_per_s);

        mutex.lock();
        if (!pet.alive) {
            mutex.unlock();
            break;
        }
        pet.update();
        mutex.unlock();
    }
}

fn render(vx: *vaxis.Vaxis, pet: *Pet, mutex: *std.Thread.Mutex) !void {
    mutex.lock();
    defer mutex.unlock();

    const win = vx.window();
    win.clear();

    const box_width = 40;
    const box_height = 40;
    const x_off = if (win.width > box_width) (win.width - box_width) / 2 else 0;
    const y_off = if (win.height > box_height) (win.height - box_height) / 2 else 0;

    const child = win.child(.{
        .x_off = x_off,
        .y_off = y_off,
        .width = box_width,
        .height = box_height,
        .border = .{
            .where = .all,
            .style = .{ .fg = .{ .index = 6 } },
        },
    });

    var title_segment = [_]vaxis.Cell.Segment{.{
        .text = "TAMAGOTCHI",
        .style = .{ .bold = true, .fg = .{ .index = 3 } },
    }};
    _ = child.print(&title_segment, .{ .row_offset = 1, .col_offset = 2 });

    var pet_segment = [_]vaxis.Cell.Segment{.{
        .text = if (pet.hunger < 30) "( @.@ )" else if (pet.happiness > 30) "(=0.0=)" else "(<^.^>)",
        .style = .{},
    }};
    _ = child.print(&pet_segment, .{ .row_offset = 3, .col_offset = 18 });

    var hunger_buf: [32]u8 = undefined;
    const hunger_text = try std.fmt.bufPrint(&hunger_buf, "Hunger:    {d}/100", .{pet.hunger});
    var hunger_segment = [_]vaxis.Cell.Segment{.{
        .text = hunger_text,
        .style = .{ .fg = if (pet.hunger < 30) .{ .index = 1 } else .{ .index = 2 } },
    }};
    _ = child.print(&hunger_segment, .{ .row_offset = 5, .col_offset = 2 });

    var happy_buf: [32]u8 = undefined;
    const happy_text = try std.fmt.bufPrint(&happy_buf, "Happiness: {d}/100", .{pet.happiness});
    var happy_segment = [_]vaxis.Cell.Segment{.{
        .text = happy_text,
        .style = .{ .fg = if (pet.happiness < 30) .{ .index = 1 } else .{ .index = 2 } },
    }};
    _ = child.print(&happy_segment, .{ .row_offset = 6, .col_offset = 2 });

    var age_buf: [32]u8 = undefined;
    const age_text = try std.fmt.bufPrint(&age_buf, "Age:       {d}s", .{pet.age_seconds});
    var age_segment = [_]vaxis.Cell.Segment{.{
        .text = age_text,
        .style = .{},
    }};
    _ = child.print(&age_segment, .{ .row_offset = 7, .col_offset = 2 });

    var controls_segment = [_]vaxis.Cell.Segment{.{
        .text = "[F}eed [P]lay [Q]uit",
        .style = .{ .fg = .{ .index = 8 } },
    }};
    _ = child.print(&controls_segment, .{ .row_offset = 9, .col_offset = 2 });
}
