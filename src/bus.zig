const memory_mod = @import("memory.zig");

pub const Bus = struct {
    ram: memory_mod.Memory,

    pub fn read(self: *const Bus, addr: u16) u8 {
        switch (addr) {
            0x0000...0x1FFF => {
                return self.ram.data[addr & 0x00FF];
            },

            else => {
                return 0;
            },
        }
    }

    pub fn write(self: *Bus, addr: u16, value: u8) void {
        switch (addr) {
            0x0000...0x1FFF => {
                self.ram.data[addr & 0xFF] = value;
            },

            else => {},
        }
    }

    pub fn init() Bus {
        var bus = Bus{
            .ram = undefined,
        };

        bus.ram = memory_mod.Memory.init();
        return bus;
    }
};
