const std = @import("std");
const azm = @import("asm.zig");

pub const instructions = @import("instructions.zig");

pub inline fn execPrologue() void {
    azm.writeWriteHandler(@intFromPtr(&writeHandler));
    azm.writeReadHandler(@intFromPtr(&readHandler));
}
inline fn epilogue(data_ptr: u64, accum: u64) void {
    azm.writeDataPtr(data_ptr);
    azm.writeAccum(accum);
    azm.writeWriteHandler(@intFromPtr(&writeHandler));
    azm.writeReadHandler(@intFromPtr(&readHandler));
}

pub fn readHandler() void {
    const data_ptr = instructions.getDataPtr();
    const accum = instructions.getAccum();
    const write_to: [*]u8 = @ptrFromInt(data_ptr);
    const stdin = std.io.getStdIn().reader();
    std.debug.print("ENTER BYTE: ", .{});
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
