const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");

pub fn main() !void {
    const instr = instructions.clearRegister(4);

    const instrs = [_]u32{instr};
    try instructions.executeInstruction(&instrs);
}

test {
    std.testing.refAllDecls(@This());
}
