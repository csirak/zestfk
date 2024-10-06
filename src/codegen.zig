const std = @import("std");

const parser = @import("parser.zig");
const instructions = @import("instructions.zig");
const azm = @import("asm.zig");

pub fn codegen(instrs: std.Arraylist(parser.Instruction), allocator: std.mem.Allocator) []u32 {
    var aarch64_instrs = allocator.alloc(u32, instrs.items.len * 2);
    for (instrs.items, 0..) |instr, i| {
        aarch64_instrs[2 * i] = switch (instr.command) {
            .right => instructions.addi(azm.data_ptr, @truncate(instr.value)),
            .left => instructions.subi(azm.data_ptr, @truncate(instr.value)),
            .read => instructions.blr(azm.read_handler),
            .write => instructions.blr(azm.write_handler),
            else => instructions.ldda,
        };

        aarch64_instrs[2 * i + 1] = switch (instr.command) {
            .jumpIfNotZero => instructions.cbnz(azm.ACCUM, instr.value * 2),
            .jumpBackIf => instructions.cbz(azm.ACCUM, instr.value * 2),
            .inc => instructions.addi(azm.ACCUM, @truncate(instr.value)),
            .dec => instructions.subi(azm.ACCUM, @truncate(instr.value)),
            else => instructions.nop,
        };
    }
}
