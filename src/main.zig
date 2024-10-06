const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");
pub const runtime = @import("runtime.zig");
pub const codegen = @import("codegen.zig");
pub const azm = @import("asm.zig");

pub fn main() !void {
    // const code = ">++++++++[<+++++++++>-]<.>++++[<+++++++>-]<+.+++++++..+++.>>++++++[<+++++++>-]<++.------------.>++++++[<+++++++++>-]<+.<.+++.------.--------.>>>++++[<++++++++>-]<+.";
    //const code = ".";
    const alloc = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile("foo.txt", .{});
    defer file.close();

    const code = try file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(code);
    const parsed = try parser.parse(code, alloc);
    const instrs = try codegen.codegen(parsed, alloc);

    for (instrs, 0..) |instr, i| {
        std.debug.print("ins: {x} ptr: {x}\n", .{ instr, i * 4 });
    }
    try runtime.execute(instrs, 30000, alloc);
}

test {
    std.testing.refAllDecls(@This());
}
