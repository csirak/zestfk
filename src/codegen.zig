const std = @import("std");

const parser = @import("parser.zig");
const instructions = @import("instructions.zig");
const azm = @import("asm.zig");

pub fn codegen(instrs: std.ArrayList(parser.Instruction), allocator: std.mem.Allocator) ![]u32 {
    var aarch64_instrs = try allocator.alloc(u32, instrs.items.len * 2 + 1);
    for (instrs.items, 0..) |instr, i| {
        aarch64_instrs[2 * i] = switch (instr.command) {
            .right => instructions.addi(azm.DATA_PTR, @intCast(instr.value * 8)),
            .left => instructions.subi(azm.DATA_PTR, @intCast(instr.value * 8)),
            .jumpIfNotZero => instructions.cbz(azm.ACCUM, @intCast(instr.value * 2)),
            .jumpBackIf => instructions.cbnz(azm.ACCUM, @intCast(@as(i16, @intCast( instr.value ) ) * -2)),
            .inc => instructions.addi(azm.ACCUM, @truncate(instr.value)),
            .dec => instructions.subi(azm.ACCUM, @truncate(instr.value)),
            .read => instructions.blr(azm.READ_HANDLER),
            .write => instructions.blr(azm.WRITE_HANDLER),
        };

        aarch64_instrs[2 * i + 1] = switch (instr.command) {
            .left, .right => instructions.ldda,
            .inc, .dec=> instructions.stda ,
            else => instructions.nop,
        };
    }
    aarch64_instrs[aarch64_instrs.len - 1] = instructions.ret;
    return aarch64_instrs;
}
