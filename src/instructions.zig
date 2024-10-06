const std = @import("std");
const azm = @import("azm.zig");

pub const ret = 0xd65f03c0;

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
    return opcode | @as(u32, rd) << 5;
}


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
