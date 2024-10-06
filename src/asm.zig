pub const DATA_PTR = 4;
pub const ACCUM = 5;
pub const READ_HANDLER = 6;
pub const WRITE_HANDLER = 7;
pub const RETRUN = 8;

pub inline fn writeReadHandler(x: u64) void {
    asm volatile ("mov x6, %[x]"
        :
        : [x] "r" (x),
    );
}

pub inline fn writeWriteHandler(x: u64) void {
    asm volatile ("mov x7, %[x]"
        :
        : [x] "r" (x),
    );
}

pub inline fn getDataPtr() u64 {
    var x: u64 = 0;
    asm volatile ("mov %[x], x4"
        : [x] "=r" (x),
    );
    return x;
}

pub fn writeDataPtr(x: u64) void {
    asm volatile ("mov x4, %[x]"
        :
        : [x] "r" (x),
    );
}

pub inline fn getAccum() u64 {
    var x: u64 = 0;
    asm volatile ("mov %[x], x5"
        : [x] "=r" (x),
    );
    return x;
}
pub fn writeAccum(x: u64) void {
    asm volatile ("mov x5, %[x]"
        :
        : [x] "r" (x),
    );
}
