const std = @import("std");
const azm = @import("asm.zig");

pub const instructions = @import("instructions.zig");

pub inline fn execPrologue() void {
    azm.writeWriteHandler(@intFromPtr(&writeHandler));
    azm.writeReadHandler(@intFromPtr(&readHandler));
}

inline fn epilogue(data_ptr: u64, accum: u64, ra: u64) void {
    azm.writeDataPtr(data_ptr);
    azm.writeAccum(accum);
    azm.writeWriteHandler(@intFromPtr(&writeHandler));
    azm.writeReadHandler(@intFromPtr(&readHandler));
    asm volatile ("mov x7, %[ra]"
        :
        : [ra] "r" (ra),
    );
}

pub fn readHandler() callconv(.C) void {
    const data_ptr = azm.getDataPtr();
    const accum = azm.getAccum();
    const write_to: [*]u8 = @ptrFromInt(data_ptr);
    const stdin = std.io.getStdIn().reader();
    std.debug.print("ENTER BYTE: ", .{});
    _ = stdin.read(write_to[0..1]) catch @panic("READ FAILED");
    const ra = @returnAddress();
    epilogue(data_ptr, accum, ra);
}

pub fn writeHandler() callconv(.C) void {
    const ra = @returnAddress();
    const data_ptr = azm.getDataPtr();
    const accum = azm.getAccum();
    const read_from: *u8 = @ptrFromInt(data_ptr);
    std.debug.print("HEY: {c}\n ra: {x}", .{ read_from.*, ra });
    epilogue(data_ptr, accum, ra);
}
