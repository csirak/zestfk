const std = @import("std");

pub fn setZero(rd: u5) u32 {
    const opcode: u32 = 0xca000000;
    const instruction: u32 = opcode | (@as(u32, rd) << 0) | (@as(u32, rd) << 5) | (@as(u32, rd) << 16);
    return instruction;
}

pub fn addi(rd: u5, imm: u12) u32 {
    const opcode: u32 = 0x91000000;

    return opcode |
        @as(u32, imm) << 10 |
        @as(u32, rd) << 5 |
        @as(u32, rd);
}

pub fn subi(rd: u5, imm: u12) u32 {
    const opcode: u32 = 0xd1000000;
    return opcode |
        @as(u32, imm) << 10 |
        @as(u32, rd) << 5 |
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

pub const ret = 0xd65f03c0;

test "clear reg" {
    const instructions = [_]u32{ setZero(4), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test "add reg" {
    const instructions = [_]u32{ addi(4, 69), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(69, x);
}
