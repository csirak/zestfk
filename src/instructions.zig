const std = @import("std");

pub fn addi(rd: u5, rn: u5, imm: u12) u32 {
    const op: u32 = 0b00_10001; // Opcode for ADD (immediate)
    const sf: u32 = 1; // 64-bit instruction
    const sh: u32 = 0; // No shift

    return op << 24 |
        sf << 31 |
        sh << 22 |
        @as(u32, imm) << 10 |
        @as(u32, rn) << 5 |
        @as(u32, rd);
}

pub fn subi(rd: u5, rn: u5, imm: u12) u32 {
    const op: u32 = 0b10_10001; // Opcode for SUB (immediate)
    const sf: u32 = 1; // 64-bit instruction
    const sh: u32 = 0; // No shift
    return op << 24 |
        sf << 31 |
        sh << 22 |
        @as(u32, imm) << 10 |
        @as(u32, rn) << 5 |
        @as(u32, rd);
}

pub fn clearRegister(rd: u5) u32 {
    const op: u32 = 0b100_10100_00000000000000; // Opcode for ORR (immediate)
    const sf: u32 = 1; // 1 for 64-bit, 0 for 32-bit
    const opc: u32 = 1; // For MOV alias of ORR
    return op |
        sf << 31 |
        opc << 29 |
        @as(u32, rd);
}

pub fn executeInstruction(instr: []const u32) !void {
    const prot = std.posix.PROT;
    const exec_ptr = try std.posix.mmap(
        null,
        @intCast(instr.len),
        prot.READ | prot.EXEC | prot.WRITE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );

    const exec_mem_region = std.mem.bytesAsSlice([]u32, exec_ptr);
    std.debug.print("{} {}\n", .{ exec_mem_region.len, instr.len });
    //@memcpy(exec_mem_region, instr);
}

test "clear reg" {
    const instr = clearRegister(4);

    const instructions = [_]u32{instr};
    try executeInstruction(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(x, 0);
}
