const std = @import("std");
const bus_mod = @import("bus.zig");
const cpu_mod = @import("cpu.zig");
const sdl = @import("sdl.zig");

pub fn main() !void {
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        return error.SDLInitFailed;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow("zmNES", 768, 720, 0) orelse return error.SDLCreateWindowFailed;

    defer sdl.SDL_DestroyWindow(window);

    var running = true;

    // ------------- main loop here -------------
    while (running) {
        var event: sdl.SDL_Event = undefined;

        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) {
                running = false;
            }
        }
        sdl.SDL_Delay(1);
    }
    // ------------- main loop here -------------

    const cpu = cpu_mod.CPU{
        .a = 10,
        .x = 20,
        .y = 30,
    };

    _ = cpu;

    var bus = bus_mod.Bus.init();
    bus.write(0x0200, 0x10);

    var value = bus.read(0x0200);
    std.debug.print("{d} \n", .{value});

    value = bus.read(0x0A00);
    std.debug.print("{d} \n", .{value});

    value = bus.read(0x1200);
    std.debug.print("{d} \n", .{value});

    value = bus.read(0x1A00);
    std.debug.print("{d} \n", .{value});
}
