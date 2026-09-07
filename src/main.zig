const std = @import("std");
const bus_mod = @import("bus.zig");
const cpu_mod = @import("cpu.zig");
const sdl = @import("sdl.zig");

const SCREEN_WIDTH: u16 = 256;
const SCREEN_HEIGHT: u16 = 240;

var framebuffer: [SCREEN_HEIGHT * SCREEN_WIDTH]u32 = undefined;
var frame: u32 = 0;

pub fn drawTextPattern(
    buf: []u32,
    frame_count: u32,
) void {
    for (0..SCREEN_HEIGHT) |y| {
        for (0..SCREEN_WIDTH) |x| {
            const index = y * SCREEN_WIDTH + x;

            if (((x + frame_count) / 16 + y / 16) % 2 == 0) {
                buf[index] = 0xFFFF0000;
            } else {
                buf[index] = 0xFF000000;
            }
        }
    }
}

pub fn main(init: std.process.Init) !void {
    // ------------- file system -------------
    var file = try std.Io.Dir.cwd().openFile(init.io, "roms/SMB.nes", .{});
    defer file.close(init.io);

    var header: [16]u8 = undefined;
    _ = try file.readStreaming(init.io, &.{&header});
    const prg_banks = header[4];
    const chr_banks = header[5];
    const prg_size = @as(usize, prg_banks) * 16 * 1024;
    const chr_size = @as(usize, chr_banks) * 8 * 1024;
    const flag6 = header[6];
    const vertical_mirroring = (flag6 & 0x01) != 0;
    const has_battery = (flag6 & 0x02) != 0;
    const has_trainer = (flag6 & 0x04) != 0;
    const flag7 = header[7];
    const mapper = (flag7 & 0xF0) | flag6 >> 4; // flag7 的高四位 | flag6 的高四位，组成了mapper

    _ = vertical_mirroring;
    _ = has_battery;
    _ = has_trainer;
    _ = mapper;

    std.debug.print("PRG ROM: {d} banks, {d} byte \n", .{ prg_banks, prg_size });
    std.debug.print("CHR ROM: {d} banks, {d} byte \n", .{ chr_banks, chr_size });
    for (header) |byte| {
        std.debug.print("0x{X:0>2} ", .{byte});
    }
    // ------------- file system -------------

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        return error.SDLInitFailed;
    }
    defer sdl.SDL_Quit();

    const window = sdl.SDL_CreateWindow("zmNES", 768, 720, 0) orelse return error.SDLCreateWindowFailed;
    defer sdl.SDL_DestroyWindow(window);

    const renderer = sdl.SDL_CreateRenderer(window, null) orelse return error.SDLCreateRendererFailed;
    defer sdl.SDL_DestroyRenderer(renderer);

    const texture = sdl.SDL_CreateTexture(
        renderer,
        sdl.SDL_PIXELFORMAT_ARGB8888,
        sdl.SDL_TEXTUREACCESS_STREAMING,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
    ) orelse return error.SDLCreateTextureFailed;
    defer sdl.SDL_DestroyTexture(texture);

    if (!sdl.SDL_SetTextureScaleMode(texture, .nearest)) {
        return error.SDLSetTextureScaleModeFailed;
    }

    var running = true;

    // ------------- main loop here -------------
    while (running) {
        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event)) {
            if (event.type == sdl.SDL_EVENT_QUIT) {
                running = false;
            }
        }

        // ------------ SDL event ------------
        // _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
        drawTextPattern(&framebuffer, frame);
        frame += 1;
        _ = sdl.SDL_UpdateTexture(texture, null, &framebuffer, SCREEN_WIDTH * @sizeOf(u32));

        _ = sdl.SDL_RenderClear(renderer);
        _ = sdl.SDL_RenderTexture(renderer, texture, null, null);
        _ = sdl.SDL_RenderPresent(renderer);

        sdl.SDL_Delay(16);
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
