const memory_mod = @import("memory.zig");
const ADDR_MASK: u16 = 0x07FF;

pub const Bus = struct {
    ram: memory_mod.Memory,

    pub fn init() Bus {
        return Bus{
            .ram = memory_mod.Memory.init(),
        };
    }

    pub fn read(self: *const Bus, addr: u16) u8 {
        switch (addr) {
            // RAM with mirrors
            0x0000...0x1FFF => return self.ram.read(addr & ADDR_MASK),

            // PPU registers with mirrors
            0x2000...0x3FFF => {
                return 0;
            },

            // APU and IO
            0x4000...0x4017 => {
                return 0;
            },

            // disabled/test
            0x4018...0x401F => {
                return 0;
            },

            // cartridge
            0x4020...0xFFFF => {
                return 0;
            },
        }
    }

    pub fn write(self: *Bus, addr: u16, value: u8) void {
        switch (addr) {
            // RAM with mirrors
            0x0000...0x1FFF => self.ram.write(addr & ADDR_MASK, value),

            // PPU registers with mirrors
            0x2000...0x3FFF => {},

            // APU and IO
            0x4000...0x4017 => {},

            // disabled/test
            0x4018...0x401F => {},

            // cartridge
            0x4020...0xFFFF => {},
        }
    }
};
