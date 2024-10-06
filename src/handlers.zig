const std = @import("std");
pub const instructions = @import("instructions.zig");

inline fn epilogue(data_ptr: u64, accum: u64) void {
    instructions.writeDataPtr(data_ptr);
    instructions.writeAccum(accum);
    instructions.writeWriteHandler(@intFromPtr(&writeHandler));
    instructions.writeReadHandler(@intFromPtr(&readHandler));
}

pub fn readHandler() void {
    const data_ptr = instructions.getDataPtr();
    const accum = instructions.getAccum();
    const write_to: [*]u8 = @ptrFromInt(data_ptr);
    const stdin = std.io.getStdIn().reader();
    _ = stdin.read(write_to[0..1]) catch @panic("READ FAILED");
    epilogue(data_ptr, accum);
}

pub fn writeHandler() void {
    const data_ptr = instructions.getDataPtr();
    const accum = instructions.getAccum();
    const read_from: *u8 = @ptrFromInt(data_ptr);
    std.debug.print("{c}", .{read_from.*});
    epilogue(data_ptr, accum);
}

test "call write" {
    const instrs = [_]u32{
        instructions.setZero(0),
        instructions.addi(0, 1),
        instructions.blr(instructions.WRITE_HANDLER),
        instructions.ret,
    };
    try instructions.execute(&instrs);

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
    try instructions.execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
