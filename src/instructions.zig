const std = @import("std");
const azm = @import("asm.zig");

// set to return with x8
pub const ret = 0xd61f0200;
pub const nop = 0xd503201f;
pub const ldda = 0xf9400085;

pub fn setZero(rd: u5) u32 {
    const opcode: u32 = 0xca000000;
    return opcode | (@as(u32, rd) << 0) | (@as(u32, rd) << 5) | (@as(u32, rd) << 16);
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
