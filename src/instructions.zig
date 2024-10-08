const std = @import("std");
const azm = @import("asm.zig");

pub const nop = 0x910000a5;
pub const ret = 0xd65f03c0;
pub const ldda = 0xf9400085;
pub const stda = 0xf9000085;
pub const addret29 = 0x8b1d03de;

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

pub fn movz_shift16(rd:u5,imm:u16) u32 {
    const opcode = 0xd2a00000;
    return opcode | @as(u32, imm)<<5 | @as(u32, rd);
}
pub fn movz(rd:u5,imm:u16) u32 {
    const opcode = 0xd280001e;
    return opcode | @as(u32, imm)<<5 | @as(u32, rd);
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
        @as(u32, @as(u19, @bitCast(label )) ) << 5 |
        @as(u32, rd);
}

pub fn cbz(rd: u5, label: i19) u32 {
    const opcode: u32 = 0xb4000000;
    return opcode |
        @as(u32, @as(u19, @bitCast(label )) ) << 5 |
        @as(u32, rd);
}

pub fn blr(rd: u5) u32 {
    const opcode: u32 = 0xd63f0000;
    return opcode | @as(u32, rd) << 5;
}
