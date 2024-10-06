const std = @import("std");

const parser = @import("parser.zig");
const instructions = @import("instructions.zig");
const azm = @import("asm.zig");

pub fn codegen(instrs: std.ArrayList(parser.Instruction), allocator: std.mem.Allocator) ![]u32 {
    var aarch64_instrs = try allocator.alloc(u32, instrs.items.len * 2);
    for (instrs.items, 0..) |instr, i| {
        aarch64_instrs[2 * i] = switch (instr.command) {
            .right => instructions.addi(azm.DATA_PTR, @truncate(instr.value)),
            .left => instructions.subi(azm.DATA_PTR, @truncate(instr.value)),
            .read => instructions.blr(azm.READ_HANDLER),
            .write => instructions.blr(azm.WRITE_HANDLER),
            else => instructions.ldda,
        };

        aarch64_instrs[2 * i + 1] = switch (instr.command) {
            .jumpIfNotZero => instructions.cbnz(azm.ACCUM, @intCast(instr.value * 2)),
            .jumpBackIf => instructions.cbz(azm.ACCUM, @intCast(instr.value * 2)),
            .inc => instructions.addi(azm.ACCUM, @truncate(instr.value)),
            .dec => instructions.subi(azm.ACCUM, @truncate(instr.value)),
            else => instructions.nop,
        };
    }

    return aarch64_instrs;
}
