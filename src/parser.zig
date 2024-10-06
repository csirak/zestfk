const std = @import("std");
const testing = std.testing;

pub const Command = enum(u8) {
    inc,
    dec,
    left,
    right,
    read,
    write,
    jumpIfNotZero,
    jumpBackIf,

    pub fn opposite(cmd: Command) Command {
        return switch (cmd) {
            .inc => .dec,
            .dec => .inc,
            .left => .right,
            .right => .left,
            .read => .write,
            .write => .read,
            .jumpIfNotZero => .jumpBackIf,
            .jumpBackIf => .jumpIfNotZero,
        };
    }

    pub fn direction(cmd: Command) i32 {
        return switch (cmd) {
            .inc, .right => 1,
            .dec, .left => -1,
            else => 0,
        };
    }
};

pub const Instruction = struct {
    command: Command,
    value: u16,
};

pub fn parse(code: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Instruction) {
    var instructions = std.ArrayList(Instruction).init(allocator);
    var jumpstack = std.ArrayList(usize).init(allocator);

    errdefer instructions.deinit();
    defer jumpstack.deinit();

    var cur_command: usize = 0;
    while (cur_command < code.len) {
        switch (code[cur_command]) {
            ' ', '\n', '\t', '\r' => {
                cur_command += 1;
                continue;
            },
            else => {},
        }
        const cur_command_type = commandType(code[cur_command]);
        var cur_value: i32 = cur_command_type.direction();
        cur_command += 1;

        while (cur_command < code.len) : (cur_command += 1) {
            switch (code[cur_command]) {
                ' ', '\n', '\t', '\r' => {
                    cur_command += 1;
                    continue;
                },
                else => {},
            }
            const next_command_type = commandType(code[cur_command]);

            if (next_command_type != cur_command_type and
                next_command_type != cur_command_type.opposite() or
                next_command_type.direction() == 0) break;

            cur_value += next_command_type.direction();
        }

        const cmd = if (cur_command_type.direction() != 0) collapse_cmd: {
            if (cur_value == 0) {
                continue;
            }
            const direction: i32 = if (cur_value < 0) -1 else 1;
            break :collapse_cmd if (direction == cur_command_type.direction()) cur_command_type else cur_command_type.opposite();
        } else cur_command_type;

        switch (cur_command_type) {
            .jumpIfNotZero => {
                try jumpstack.append(instructions.items.len);
            },
            .jumpBackIf => {
                const jump = jumpstack.pop();
                cur_value = @intCast(jump);
            cur_value -= @as(u16, @truncate( instructions.items.len  ));
                instructions.items[jump].value = @truncate(@abs(cur_value)) ;
            },
            else => {},
        }
        try instructions.append(.{ .command = cmd, .value = @truncate(@abs(cur_value)) });
    }

    if (jumpstack.items.len != 0) {
        return error.JumpStackNotEmpty;
    }
    return instructions;
}

inline fn commandType(cmd: u8) Command {
    return switch (cmd) {
        '+' => .inc,
        '-' => .dec,
        '>' => .right,
        '<' => .left,
        ',' => .read,
        '.' => .write,
        '[' => .jumpIfNotZero,
        ']' => .jumpBackIf,
        else => {
            std.debug.print("MESS IP: {}", .{cmd});
            @panic("invalid command");
        },
    };
}

test "basic parse accum" {
    const input = "++---";
    const output = [_]Instruction{.{ .command = .dec, .value = 1 }};
    const instructions = try parse(input, testing.allocator);
    defer instructions.deinit();
    try testing.expect(instructions.items.len == output.len);
    for (instructions.items, 0..) |instruction, i| {
        try testing.expect(instruction.command == output[i].command);
        try testing.expect(instruction.value == output[i].value);
    }
}
test "basic parse data" {
    const input = "<<>><";
    const output = [_]Instruction{.{ .command = .left, .value = 1 }};
    const instructions = try parse(input, testing.allocator);
    defer instructions.deinit();
    try testing.expect(instructions.items.len == output.len);
    for (instructions.items, 0..) |instruction, i| {
        try testing.expect(instruction.command == output[i].command);
        try testing.expect(instruction.value == output[i].value);
    }
}

test "basic parse no-op" {
    const input = "+++++-----";
    const output = [_]Instruction{};
    const instructions = try parse(input, testing.allocator);
    defer instructions.deinit();
    try testing.expect(instructions.items.len == output.len);
}

test "basic parse io" {
    const input = "+++++-----...";
    const output = [_]Instruction{
        .{ .command = .write, .value = 0 },
        .{ .command = .write, .value = 0 },
        .{ .command = .write, .value = 0 },
    };
    const instructions = try parse(input, testing.allocator);
    defer instructions.deinit();
    try testing.expect(instructions.items.len == output.len);
    for (instructions.items, 0..) |instruction, i| {
        try testing.expect(instruction.command == output[i].command);
        try testing.expect(instruction.value == output[i].value);
    }
}

test "basic parse jumps" {
    const input = "+[-]";
    const output = [_]Instruction{
        .{ .command = .inc, .value = 1 },
        .{ .command = .jumpIfNotZero, .value = 3 },
        .{ .command = .dec, .value = 1 },
        .{ .command = .jumpBackIf, .value = 1 },
    };

    const instructions = try parse(input, testing.allocator);
    defer instructions.deinit();

    try testing.expect(instructions.items.len == output.len);
    for (instructions.items, 0..) |instruction, i| {
        try testing.expect(instruction.command == output[i].command);
        try testing.expect(instruction.value == output[i].value);
    }
}

test "basic parse jumpstack underflow" {
    const input = "+[-";
    const instructions = parse(input, testing.allocator);
    try std.testing.expectError(error.JumpStackNotEmpty, instructions);
}
