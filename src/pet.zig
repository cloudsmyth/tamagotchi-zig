const std = @import("std");

pub const Pet = struct {
    hunger: u8,
    happiness: u8,
    age_seconds: u64,
    last_update: i64,
    alive: bool,

    pub fn init() Pet {
        return Pet{ .hunger = 50, .happiness = 50, .age_seconds = 0, .last_update = std.time.timestamp(), .alive = true };
    }

    pub fn update(self: *Pet) void {
        const now = std.time.timestamp();
        const elapsed = now - self.last_update;
        if (elapsed < 1) return;

        const minutes_elapsed = @divFloor(elapsed, 60);

        if (minutes_elapsed > 0) {
            const decay = @as(u8, @intCast(@divFloor(minutes_elapsed, 100)));

            if (self.hunger > decay) {
                self.hunger -= decay;
            } else {
                self.hunger = 0;
                self.alive = false;
            }

            if (self.happiness > decay) {
                self.happiness -= decay;
            } else {
                self.happiness = 0;
            }
        }
        self.age_seconds += @as(u64, @intCast(elapsed));
        self.last_update = now;
    }

    pub fn feed(self: *Pet) void {
        if (self.hunger + 20 > 100) {
            self.hunger = 100;
        } else {
            self.hunger += 20;
        }
    }

    pub fn play(self: *Pet) void {
        if (self.happiness + 20 > 100) {
            self.happiness += 100;
        } else {
            self.happiness += 20;
        }
    }
};
