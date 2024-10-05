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

pub fn execute(instr: []const u32) !void {
    const prot = std.posix.PROT;
    const exec_ptr = try std.posix.mmap(
        null,
        @intCast(instr.len * @sizeOf(u32)),
        prot.READ | prot.EXEC | prot.WRITE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );

    const exec_mem_region = std.mem.bytesAsSlice(u32, exec_ptr);
    @memcpy(exec_mem_region, instr);
    std.debug.print("inst: 0x{x}\n", .{exec_mem_region[0]});
    std.debug.print("addr: {*}\n", .{exec_mem_region.ptr});

    runAndRet(exec_ptr.ptr);
}

fn runAndRet(location: *anyopaque) void {
    asm volatile ("mov x30, %[ra]"
        :
        : [ra] "r" (@returnAddress()),
    );
    asm volatile ("blr %[loc]"
        :
        : [loc] "r" (location),
    );
}
fn setZero(rd: u5) u32 {
    const opcode: u32 = 0xca000000;
    const instruction: u32 = opcode | (@as(u32, rd) << 0) | (@as(u32, rd) << 5) | (@as(u32, rd) << 16);
    return instruction;
}
pub const ret = 0xd65f03c0;
const clear4 = 0xca040084;
test "clear reg" {
    //const instr = setZero(4);
    const instructions = [_]u32{ setZero(4), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
