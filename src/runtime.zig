const std = @import("std");

const handlers = @import("handlers.zig");
const azm = @import("asm.zig");
const instructions = @import("instructions.zig");

const cache = @cImport({
    @cInclude("cache.h");
});

pub const MEM_SIZE = 30000;
var memory = [_]u64{0} ** MEM_SIZE;

pub fn execute(instr: []const u32) !void {
    const prot = std.posix.PROT;
    const exec_ptr = try std.posix.mmap(
        null,
        @intCast(instr.len * @sizeOf(u32)),
        prot.EXEC | prot.WRITE,
        .{ .TYPE = .PRIVATE, .ANONYMOUS = true },
        -1,
        0,
    );
    const exec_mem_region = std.mem.bytesAsSlice(u32, exec_ptr);
    @memcpy(exec_mem_region, instr);
    cache.cache_clr(exec_ptr.ptr, @truncate(exec_ptr.len));

    runAndRet(exec_ptr.ptr, &memory);
    asm volatile ("ret_label:");
    asm volatile ("add sp, sp, 0x50");
    handlers.writeBufferFlush();
}

fn runAndRet(location: *anyopaque, data: *anyopaque) void {
    handlers.execPrologue();
    azm.writeDataPtr(@intFromPtr(data));
    azm.writeAccum(0);
    asm volatile ("br %[x]"
        :
        : [x] "r" (location),
    );
}

test "clear reg" {
    const instrs = [_]u32{ instructions.setZero(9), instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x9"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test "clear reg nop" {
    const instrs = [_]u32{ instructions.nop, instructions.setZero(4), instructions.nop, instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test "add reg" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.addi(4, 69), instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(69, x);
}

test "ldda" {
    const instrs = [_]u32{ instructions.setZero(azm.ACCUM), instructions.addi(azm.ACCUM, 69), instructions.ldda, instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x5"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}

test "add reg nop" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.setZero(4), instructions.addi(4, 69), instructions.setZero(4), instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(69, x);
}

test "sub reg" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.addi(4, 489), instructions.subi(4, 69), instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(420, x);
}

test "cbnz" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.addi(4, 489), instructions.cbnz(4, 2), instructions.subi(4, 69), instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(489, x);
}
test "cbz" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.cbz(4, 2), instructions.addi(4, 69), instructions.ret };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

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
        instructions.blr(azm.WRITE_HANDLER),
        instructions.ret,
    };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

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
        instructions.blr(azm.READ_HANDLER),
        instructions.ret,
    };
    try execute(&instrs, MEM_SIZE, std.heap.page_allocator);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
