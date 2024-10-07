const std = @import("std");

const parser = @import("parser.zig");
const instructions = @import("instructions.zig");
const azm = @import("asm.zig");

extern fn ret_label() void;

pub fn codegen(instrs: std.ArrayList(parser.Instruction), allocator: std.mem.Allocator) ![]u32 {
    var aarch64_instrs = try allocator.alloc(u32, instrs.items.len * 2 + 4);
    for (instrs.items, 0..) |instr, i| {
        aarch64_instrs[2 * i] = switch (instr.command) {
            .right => instructions.addi(azm.DATA_PTR, @intCast(instr.value * 8)),
            .left => instructions.subi(azm.DATA_PTR, @intCast(instr.value * 8)),
            .jumpIfNotZero => instructions.cbz(azm.ACCUM, @intCast(instr.value * 2)),
            .jumpBackIf => instructions.cbnz(azm.ACCUM, @intCast(@as(i16, @intCast(instr.value)) * -2)),
            .inc => instructions.addi(azm.ACCUM, @truncate(instr.value)),
            .dec => instructions.subi(azm.ACCUM, @truncate(instr.value)),
            .read => instructions.blr(azm.READ_HANDLER),
            .write => instructions.blr(azm.WRITE_HANDLER),
        };

        aarch64_instrs[2 * i + 1] = switch (instr.command) {
            .left, .right => instructions.ldda,
            .inc, .dec => instructions.stda,
            else => instructions.nop,
        };
    }

    const end = instrs.items.len * 2;
    const ret_label_32: u32 = @truncate(@intFromPtr(&ret_label));
    const ret_label_upper: u16 = @truncate(ret_label_32 >> 16);
    const ret_label_lower: u16 = @truncate(ret_label_32 & 0xFFFF);
    aarch64_instrs[end] = instructions.movz(azm.LINK_REGISTER, ret_label_lower);
    aarch64_instrs[end + 1] = instructions.movz_shift16(29, ret_label_upper);
    aarch64_instrs[end + 2] = instructions.addret29;
    aarch64_instrs[end + 3] = instructions.ret;
    return aarch64_instrs;
}
