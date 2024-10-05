const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");

pub fn main() !void {
    //    const instr = instructions.setZero(4);

    const instrs = [_]u32{instructions.ret(30)};
    try instructions.execute(&instrs);
}

test {
    std.testing.refAllDecls(@This());
}

// ra
// sp
