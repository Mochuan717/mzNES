const std = @import("std");
const Bus = @import("bus.zig").Bus;

const Flags = struct {
    const Carry: u8 = 0x01;
    const Zero: u8 = 0x02;
    const InterruptDisable: u8 = 0x04;
    const Decimal: u8 = 0x08;
    const Break: u8 = 0x10;
    const Unused: u8 = 0x20;
    const Overflow: u8 = 0x40;
    const Negative: u8 = 0x80;
};

const AddressingMode = enum {
    implied,
    immediate,
};

const Operation = enum {
    sei,
    cld,
    lda,
};

const Instruction = struct {
    operation: Operation,
    mode: AddressingMode,
    bytes: u8,
    cycles: u8,
};

// ======== CPU ========
pub const CPU = struct {
    a: u8,
    x: u8,
    y: u8,

    sp: u8,
    pc: u16,
    status: u8,

    cycles: u64,

    bus: *Bus,

    pub fn init(bus: *Bus) CPU {
        return .{
            .a = 0,
            .x = 0,
            .y = 0,
            .sp = 0,
            .pc = 0,
            .status = 0,
            .cycles = 0,
            .bus = bus,
        };
    }

    pub fn reset(self: *CPU) void {
        const reset_low = self.bus.read(0xFFFC);
        const reset_high = self.bus.read(0xFFFD);
        const reset_addr = readU16LE(reset_low, reset_high);
        self.pc = reset_addr;
    }

    pub fn fetchByte(self: *CPU) u8 {
        const code = self.bus.read(self.pc);
        std.debug.print("{X:0>2}  ", .{code});
        self.pc += 1;
        return code;
    }

    pub fn setFlag(self: *CPU, flag: u8) void {
        self.status |= flag;
    }

    pub fn clearFlag(self: *CPU, flag: u8) void {
        self.status &= ~flag;
    }

    pub fn run(self: *CPU) !void {
        std.debug.print("{X:0>4}    ", .{self.pc});
        const code = self.fetchByte();
        const ins = try decode(code);
        self.execute(ins);
    }

    // ======== OPCODE TABLE ========
    pub fn decode(opcode: u8) !Instruction {
        return switch (opcode) {
            0x78 => .{
                .operation = .sei,
                .mode = .implied,
                .bytes = 1,
                .cycles = 2,
            },

            0xD8 => .{
                .operation = .cld,
                .mode = .implied,
                .bytes = 1,
                .cycles = 2,
            },

            0xA9 => .{
                .operation = .lda,
                .mode = .immediate,
                .bytes = 2,
                .cycles = 2,
            },

            else => error.UnknownOperation,
        };
    }
    // -------- OPCODE TABLE --------

    // ======== Resolve addressing mode ========
    pub fn resolveAddrMode(self: *CPU, mode: AddressingMode, steps: u8) u16 {
        var addr: u16 = undefined;
        var stp: u8 = steps;
        switch (mode) {
            .immediate => {
                addr = self.pc;
                while (stp - 1 > 0) {
                    _ = self.fetchByte();
                    stp -= 1;
                }
                return addr;
            },
            else => return 0,
        }
    }

    // ======== OPCODE EXCUTION ========
    pub fn execute(self: *CPU, ins: Instruction) void {
        const addr = self.resolveAddrMode(ins.mode, ins.bytes);
        switch (ins.operation) {
            .sei => {
                self.setFlag(Flags.InterruptDisable);
                std.debug.print("sei", .{});
            },
            .cld => {
                self.clearFlag(Flags.Decimal);
                std.debug.print("cld", .{});
            },
            .lda => {
                const value = self.bus.read(addr);
                self.a = value;
                self.setFlag(Flags.Zero);
                self.setFlag(Flags.Negative);
                std.debug.print("lda  {X:0>2}", .{value});
            },
        }
        self.cycles += ins.cycles;
        std.debug.print("    cycles={d}\n", .{self.cycles});
    }
    // -------- OPCODE EXCUTION --------
};

pub fn readU16LE(low: u8, high: u8) u16 {
    const temp: u16 = (@as(u16, high) << 8) | (@as(u16, low));
    return temp;
}
