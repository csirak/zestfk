const std = @import("std");

pub const RETURN: u32 = 0xd65f03c0;
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

pub fn setZero(rd: u5) u32 {
    const op: u32 = 0b100_10100_00000000000000; // Opcode for ORR (immediate)
    const sf: u32 = 1; // 1 for 64-bit, 0 for 32-bit
    const opc: u32 = 1; // For MOV alias of ORR
    return op |
        sf << 31 |
        opc << 29 |
        @as(u32, rd);
}

pub fn execute(instr: []const u32) !void {
    const ra = @returnAddress();
    const prot = std.posix.PROT;
    const exec_ptr = try std.posix.mmap(
        null,
        @intCast(instr.len * @sizeOf(u32)),
        prot.READ | prot.EXEC | prot.WRITE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    _ = ra;

    const exec_mem_region = std.mem.bytesAsSlice(u32, exec_ptr);
    @memcpy(exec_mem_region, instr);
    runAndRet(exec_mem_region.ptr, @returnAddress());
}

fn runAndRet(location: *anyopaque, ra: u64) void {
    asm volatile ("mov x30, %[ra]"
        :
        : [ra] "r" (ra),
    );
    asm volatile ("blr %[loc]"
        :
        : [loc] "r" (location),
    );
}

test "clear reg" {
    //const instr = setZero(4);
    const instructions = [_]u32{RETURN};
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
