#!/bin/bash

# Default value for the Zig executable
DEFAULT_ZIG_EXEC="/home/debian/zig-linux-aarch64-0.13.0/zig"
ZIG_EXEC="${1:-$DEFAULT_ZIG_EXEC}"

# SSH command
ssh debian@pi1 "cd zestfk && git pull && $ZIG_EXEC build run --release=fast"
