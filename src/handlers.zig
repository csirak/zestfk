const std = @import("std");
const azm = @import("asm.zig");
const runtime = @import("runtime.zig");

pub const instructions = @import("instructions.zig");

const BUF_SIZE = 1024;
var write_buffer = [_]u8{0} ** BUF_SIZE;
var cur: usize = 0;

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

pub fn readHandler() callconv(.C) void {
    const data_ptr = azm.getDataPtr();
    const accum = azm.getAccum();
    const write_to_ptr: *u64 = @ptrFromInt(data_ptr);
    writeBufferFlush();
    const stdin = std.io.getStdIn().reader();
    var read_buf = [_]u8{0} ** 8;
    std.debug.print("> ", .{});
    _ = stdin.readUntilDelimiterOrEof(read_buf[0..], '\n') catch |e| std.debug.print("error: {}", .{e});
    std.debug.print("READ: {s}", .{read_buf[0..1]});
    write_to_ptr.* = @intCast(read_buf[0]);
    epilogue(data_ptr, accum);
}

pub fn writeHandler() callconv(.C) void {
    const data_ptr = azm.getDataPtr();
    const accum = azm.getAccum();
    const read_from: *u64 = @ptrFromInt(data_ptr);
    const byte: u8 = @truncate(read_from.*);
    write_buffer[cur] = byte;

    if (cur + 1 >= BUF_SIZE) {
        writeBufferFlush();
    } else {
        cur += 1;
    }
    epilogue(data_ptr, accum);
}

pub fn writeBufferFlush() void {
    const stdout = std.io.getStdOut().writer();
    _ = stdout.write(write_buffer[0..cur]) catch @panic("WRITE FAILED");
    cur = 0;
}
