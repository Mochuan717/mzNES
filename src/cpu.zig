pub const CPU = struct {
    a: u8,
    x: u8,
    y: u8,

    pub fn loadA(self: *CPU, value: u8) void {
        self.a = value;
    }
};
