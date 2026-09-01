const std = @import("std");
const bus_mod = @import("bus.zig");

const CPU = struct {
    a: u8,
    x: u8,
    y: u8,

    pub fn loadA(self: *CPU, value: u8) void {
        self.a = value;
    }
};

pub fn main() void {
    const cpu = CPU{
        .a = 10,
        .x = 20,
        .y = 30,
    };

    _ = cpu;
    var bus = bus_mod.Bus.init();
    bus.write(0x0200, 0x0010);
    const value = bus.read(0x0200);
    std.debug.print("{d}", .{value});
}
