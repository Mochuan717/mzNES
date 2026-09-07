pub const Mirroring = enum {
    horizontal,
    vertical,
};

pub const iNESHeader = struct {
    magic_num: [4]u8,
    prg_bank: u8,
    chr_bank: u8,
    mapper: u8,
    mirroring: Mirroring,
    has_battery: bool,
    has_trainer: bool,
};

pub fn parseHeader(header: [16]u8) !iNESHeader {
    if (header[0..4].* != [4]u8{ 0x4E, 0x45, 0x53, 0x1A }) {
        return error.InvalidHeader;
    }

    const inh = iNESHeader{
        .magic_num = header[0..4].*,
    };
    return inh;
}
