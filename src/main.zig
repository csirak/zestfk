const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");

pub fn main() !void {
    const instrs = [_]u32{
        instructions.setZero(0),
        instructions.addi(0, 1),
        instructions.blr(3),
        instructions.ret,
    };
    try instructions.execute(&instrs);
}
