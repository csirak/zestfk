const std = @import("std");
const handlers = @import("handlers.zig");
const azm = @import("asm.zig");
const instructions = @import("instructions.zig");

pub fn execute(instr: []const u32, mem_size: usize) !void {
    const prot = std.posix.PROT;
    const exec_ptr = try std.posix.mmap(
        null,
        @intCast(instr.len * @sizeOf(u32)),
        prot.READ | prot.EXEC | prot.WRITE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );

    const data = try std.heap.page_allocator.alloc(u8, mem_size);
    defer std.heap.page_allocator.free(data);

    defer std.posix.munmap(exec_ptr);

    const exec_mem_region = std.mem.bytesAsSlice(u32, exec_ptr);
    @memcpy(exec_mem_region, instr);

    std.debug.print("inst: 0x{x}\n", .{exec_mem_region[0]});
    std.debug.print("ptr: 0x{*}\n", .{exec_mem_region.ptr});
    runAndRet(exec_ptr.ptr, data.ptr);
}

fn runAndRet(location: *anyopaque, data: [*]u8) void {
    handlers.execPrologue();
    azm.writeDataPtr(@intFromPtr(data));
    asm volatile ("blr %[loc]"
        :
        : [loc] "r" (location),
    );
}

test "clear reg" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.ret };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test "add reg" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.addi(4, 69), instructions.ret };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(69, x);
}

test "sub reg" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.addi(4, 489), instructions.subi(4, 69), instructions.ret };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(420, x);
}

test "cbnz" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.addi(4, 489), instructions.cbnz(4, 2), instructions.subi(4, 69), instructions.ret };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(489, x);
}
test "cbz" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.cbz(4, 2), instructions.addi(4, 69), instructions.ret };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
test "call write" {
    const instrs = [_]u32{
        instructions.setZero(0),
        instructions.addi(0, 1),
        instructions.blr(instructions.WRITE_HANDLER),
        instructions.ret,
    };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test "call read" {
    const instrs = [_]u32{
        instructions.setZero(0),
        instructions.addi(0, 1),
        instructions.blr(instructions.READ_HANDLER),
        instructions.ret,
    };
    try execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
