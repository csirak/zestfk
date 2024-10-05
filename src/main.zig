const std = @import("std");
pub const parser = @import("parser.zig");
pub const instructions = @import("instructions.zig");

pub fn main() !void {}

test {
    std.testing.refAllDecls(@This());
}
