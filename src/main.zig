const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");

pub fn main() !void {
    //    const instr = instructions.setZero(4);
}

test {
    std.testing.refAllDecls(@This());
}

// ra
// sp
