const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");
pub const runtime = @import("runtime.zig");
pub const codegen = @import("codegen.zig");
pub const azm = @import("asm.zig");

pub fn main() !void {
    // const code = "+++>+++";
    // const alloc = std.heap.page_allocator;
    // const parsed = try parser.parse(code, alloc);
    // const instrs = try codegen.codegen(parsed, alloc);
    // try runtime.execute(instrs, 30000, alloc);
    const instrs = [_]u32{ instructions.setZero(azm.ACCUM), instructions.addi(azm.ACCUM, 69), instructions.ldda, instructions.ret };
    try runtime.execute(&instrs, 30000, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x5"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test {
    std.testing.refAllDecls(@This());
}
