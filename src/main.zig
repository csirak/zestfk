const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");
pub const runtime = @import("runtime.zig");
pub const azm = @import("asm.zig");

pub fn main() !void {
    const instrs = [_]u32{
        instructions.setZero(0),
        instructions.addi(0, 1),
        instructions.blr(azm.READ_HANDLER),
        instructions.ret,
    };
    try runtime.execute(&instrs, 30000);
}

test {
    std.testing.refAllDecls(@This());
}
