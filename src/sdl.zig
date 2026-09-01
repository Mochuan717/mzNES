pub const SDL_Window = opaque {};

pub extern fn SDL_Init(flags: u32) bool;
pub extern fn SDL_Quit() void;

pub extern fn SDL_CreateWindow(
    title: [*:0]const u8,
    w: c_int,
    h: c_int,
    flags: u64,
) ?*SDL_Window;

pub extern fn SDL_DestroyWindow(window: *SDL_Window) void;

pub extern fn SDL_Delay(ms: u32) void;

pub const SDL_INIT_VIDEO: u32 = 0x20;

pub const SDL_Event = extern union {
    type: u32,
    padding: [128]u8,
};

pub extern fn SDL_PollEvent(event: *SDL_Event) bool;
pub const SDL_EVENT_QUIT: u32 = 0x100;
