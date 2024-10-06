const std = @import("std");
pub const handlers = @import("handlers.zig");

const HANDLER = 3;
const DATA_PTR = 4;
const ACCUM = 5;

pub fn writeHandler(x: u64) void {
    asm volatile ("mov x3, %[x]"
        :
        : [x] "r" (x),
    );
}
pub fn getDataPtr() u64 {
    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    return x;
}

pub fn writeDataPtr(x: u64) void {
    asm volatile ("mov x4, %[x]"
        :
        : [x] "r" (x),
    );
}

pub fn getAccum() u64 {
    var x: u64 = 0;
    asm volatile ("mov %[x], x5"
        : [x] "=r" (x),
    );
    return x;
}
pub fn writeAccum(x: u64) void {
    asm volatile ("mov x5, %[x]"
        :
        : [x] "r" (x),
    );
}

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

pub fn cbnz(rd: u5, label: i19) u32 {
    const opcode: u32 = 0xb5000000;
    return opcode |
        @as(u32, @intCast(label)) << 5 |
        @as(u32, rd);
}

pub fn cbz(rd: u5, label: i19) u32 {
    const opcode: u32 = 0xb4000000;
    return opcode |
        @as(u32, @intCast(label)) << 5 |
        @as(u32, rd);
}

pub fn blr(rd: u5) u32 {
    const opcode: u32 = 0xd63f0000;
    return opcode | @as(u32, rd) << 1;
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

    defer std.posix.munmap(exec_ptr);

    const exec_mem_region = std.mem.bytesAsSlice(u32, exec_ptr);
    @memcpy(exec_mem_region, instr);

    writeHandler(@intFromPtr(&handlers.callHandler));
    runAndRet(exec_ptr.ptr);
}

fn runAndRet(location: *anyopaque) void {
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
    const instructions = [_]u32{ setZero(4), addi(4, 69), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(69, x);
}

test "sub reg" {
    const instructions = [_]u32{ setZero(4), addi(4, 489), subi(4, 69), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(420, x);
}

test "cbnz" {
    const instructions = [_]u32{ setZero(4), addi(4, 489), cbnz(4, 2), subi(4, 69), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(489, x);
}
test "cbz" {
    const instructions = [_]u32{ setZero(4), cbz(4, 2), addi(4, 69), ret };
    try execute(&instructions);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
