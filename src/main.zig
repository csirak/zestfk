const std = @import("std");

pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");
pub const runtime = @import("runtime.zig");
pub const codegen = @import("codegen.zig");
pub const azm = @import("asm.zig");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const args = try std.process.argsWithAllocator(alloc);
    _ = args.next();
    const file_name = args.next().?;
    const file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();

    const code = try file.readToEndAlloc(alloc, std.math.maxInt(usize));
    defer alloc.free(code);
    const parsed = try parser.parse(code, alloc);
    const instrs = try codegen.codegen(parsed, alloc);

    try runtime.execute(instrs);
}

test {
    std.testing.refAllDecls(@This());
}
