const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");

pub fn main() !void {
        const instr = instructions.clearRegister(4);

    const instructions = [_]u32{instr};
    try instructions.executeInstruction(&instructions);

}

test {
    std.testing.refAllDecls(@This());
}
