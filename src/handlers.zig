const std = @import("std");
const instructions = @import("instructions.zig");

const READ_HANDLER = 0;
const WRITE_HANDLER = 1;

pub fn callHandler(handler_id: u64) callconv(.C) void {
    const data_ptr = instructions.getDataPtr();
    const accum = instructions.getAccum();
    switch (handler_id) {
        READ_HANDLER => readHandler(data_ptr),
        WRITE_HANDLER => writeHandler(data_ptr),
        else => @panic("invalid handler id"),
    }

    instructions.writeAccum(accum);
    instructions.writeDataPtr(data_ptr);
}

fn readHandler(data_ptr: u64) void {
    const write_to: [*]u8 = @ptrFromInt(data_ptr);
    const stdin = std.io.getStdIn().reader();
    stdin.read(write_to[0..1]) catch @panic("READ FAILED");
}

fn writeHandler(data_ptr: u64) void {
    std.debug.print("HELLOW WORLD", .{});
    const read_from: *u8 = @ptrFromInt(data_ptr);
    std.debug.print("{c}", .{read_from.*});
}

test "call write" {
    const instrs = [_]u32{ instructions.setZero(4), instructions.ret };
    try instructions.execute(&instrs);

    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    try std.testing.expectEqual(0, x);
}
