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
    accumulator,
    implied,
    immediate,
    absolute,
    absolute_x,
    absolute_y,
    zeropage,
    zeropage_x,
    zeropage_y,
    indexed_indirect,
    indirect_indexed,
    // 特殊控制流
    indirect,
    relative,
};

const Operation = enum {
    // Load/store
    lda,
    ldx,
    ldy,
    sta,
    stx,
    sty,

    // Register
    tax,
    tay,
    txa,
    tya,
    tsx,
    txs,

    // Stack
    pha,
    php,
    pla,
    plp,

    // Arithmetic
    adc,
    sbc,

    // Logic
    and_,
    ora,
    eor,

    // Compare
    cmp,
    cpx,
    cpy,

    // Increment/decrement
    inc,
    inx,
    iny,
    dec,
    dex,
    dey,

    // Shift
    asl,
    lsr,
    rol,
    ror,

    // Jump
    jmp,
    jsr,
    rts,

    // Branch
    bcc,
    bcs,
    beq,
    bmi,
    bne,
    bpl,
    bvc,
    bvs,

    // Flags
    clc,
    cld,
    cli,
    clv,
    sec,
    sed,
    sei,

    // Other
    nop,
    brk,
    rti,
};

const Instruction = struct {
    operation: Operation,
    mode: AddressingMode,
    bytes: u8,
    cycles: u8,
    page_cycle: bool = false,
};

const AddressResult = struct {
    addr: u16,
    page_crossed: bool = false,
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
        self.pc += 1;
        return code;
    }

    pub fn fetchWord(self: *CPU) u16 {
        const addr_low = self.fetchByte();
        const addr_high = self.fetchByte();
        const final_addr: u16 = readU16LE(addr_low, addr_high);
        return final_addr;
    }

    pub fn setFlag(self: *CPU, flag: u8, value: bool) void {
        if (value) {
            self.status |= flag;
        } else {
            self.status &= ~flag;
        }
    }

    pub fn trace(self: *CPU, pc: u16, ins: Instruction) void {
        std.debug.print("{X:0>4}    ", .{pc});
        var i: u8 = 0;
        while (i < ins.bytes) : (i += 1) {
            std.debug.print("{X:0>2}  ", .{self.bus.read(pc + @as(u16, i))});
        }

        std.debug.print(
            "{s}  A:{X:0>2} X:{X:0>2} Y:{X:0>2} P:{X:0>2} SP:{X:0>2} CYC:{d}\n",
            .{
                @tagName(ins.operation),
                self.a,
                self.x,
                self.y,
                self.status,
                self.sp,
                self.cycles,
            },
        );
    }

    pub fn step(self: *CPU) !void {
        const pc_before = self.pc;

        const code = self.fetchByte();
        const ins = try decode(code);

        self.trace(pc_before, ins);

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
    pub fn resolveAddrMode(self: *CPU, mode: AddressingMode) AddressResult {
        return switch (mode) {
            .accumulator => .{ .addr = 0 },
            .implied => .{ .addr = 0 },

            .immediate => blk: {
                const final_addr = self.pc;
                self.pc += 1;
                break :blk .{ .addr = final_addr };
            },

            .absolute => blk: {
                const final_addr = self.fetchWord();
                break :blk .{ .addr = final_addr };
            },

            .absolute_x => blk: {
                const base_addr = self.fetchWord();
                const final_addr = base_addr +% @as(u16, self.x);
                // check page crossed
                const pagecros: bool = (base_addr & 0xFF00) != (final_addr & 0xFF00);

                break :blk .{
                    .addr = final_addr,
                    .page_crossed = pagecros,
                };
            },

            .absolute_y => blk: {
                const base_addr = self.fetchWord();
                const final_addr = base_addr +% @as(u16, self.y);
                // check page crossed
                const pagecros: bool = (base_addr & 0xFF00) != (final_addr & 0xFF00);

                break :blk .{
                    .addr = final_addr,
                    .page_crossed = pagecros,
                };
            },

            .zeropage => .{ .addr = @as(u16, self.fetchByte()) },
            .zeropage_x => .{ .addr = @as(u16, self.fetchByte() +% self.x) },
            .zeropage_y => .{ .addr = @as(u16, self.fetchByte() +% self.y) },

            .indexed_indirect => blk: {
                const base_addr = self.fetchByte() +% self.x;
                const indirect_low = self.bus.read(base_addr);
                const indirect_high = self.bus.read(base_addr +% 1);
                const final_addr = readU16LE(indirect_low, indirect_high);
                break :blk .{ .addr = final_addr };
            },

            .indirect_indexed => blk: {
                const base_addr = self.fetchByte();
                const indirect_low = self.bus.read(base_addr);
                const indirect_high = self.bus.read(base_addr +% 1);
                const final_addr_before = readU16LE(indirect_low, indirect_high);
                const final_addr = final_addr_before +% @as(u16, self.y);
                // check page crossed
                const pagecros: bool = (final_addr_before & 0xFF00) != (final_addr & 0xFF00);

                break :blk .{
                    .addr = final_addr,
                    .page_crossed = pagecros,
                };
            },

            // 特殊控制流
            .indirect => blk: {
                const base_addr = self.fetchWord();
                const indirect_low = self.bus.read(base_addr);
                // 6502经典bug。JMP跳转时，低位为0x02FF时，+1 后等于 0x0200
                const indirect_high = if (base_addr & 0x00FF == 0x00FF)
                    self.bus.read(base_addr & 0xFF00)
                else
                    self.bus.read(base_addr + 1);

                const final_addr = readU16LE(indirect_low, indirect_high);
                break :blk .{ .addr = final_addr };
            },

            .relative => blk: {
                const raw_offset = self.fetchByte();
                const offset: i8 = @bitCast(raw_offset);
                const offset_u16: u16 = @bitCast(@as(i16, offset));
                const final_addr_before = self.pc;
                const final_addr = final_addr_before +% offset_u16;
                // check page crossed
                const pagecros = (final_addr_before & 0xFF00) != (final_addr & 0xFF00);

                break :blk .{
                    .addr = final_addr,
                    .page_crossed = pagecros,
                };
            },
        };
    }

    // -------- Resolve addressing mode --------

    // ======== OPCODE EXCUTION ========
    pub fn execute(self: *CPU, ins: Instruction) void {
        const addr_res = self.resolveAddrMode(ins.mode);
        switch (ins.operation) {
            .sei => {
                self.setFlag(Flags.InterruptDisable, true);
            },
            .cld => {
                self.setFlag(Flags.Decimal, false);
            },
            .lda => {
                const value = self.bus.read(addr_res.addr);
                self.a = value;
                self.setFlag(Flags.Zero, self.a == 0);
                self.setFlag(Flags.Negative, self.a & 0x80 != 0);
            },
        }
        self.cycles += ins.cycles;
    }
    // -------- OPCODE EXCUTION --------
};

pub fn readU16LE(low: u8, high: u8) u16 {
    const temp: u16 = (@as(u16, high) << 8) | (@as(u16, low));
    return temp;
}
