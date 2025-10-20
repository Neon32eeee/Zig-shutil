# Shutil - Simplified Command Execution Library for Zig

Shutil is a lightweight, open-source static library for Zig that simplifies command-line operations and process execution. It provides a convenient interface for running shell commands, managing files, and handling package management tasks across different Linux package managers (`apt`, `dnf`, `pacman`, `yum`). The library also includes utilities for retrieving user information.

## Features

- Execute shell commands with ease using `cmd.run`, and root commands using `cmd.sudo.run`.
- File operations: copy (`cp`), move (`mv`), create directories (`mkdir`), create files (`touch`), display file contents (`cat`), echo text (`echo`), return faint path (`pwd`), remove file or dir (`rm`).
- Search: file (`find`), text in file (`grep`), command (`isAvilableCommand`).
- Package management support for `apt`, `dnf`, `pacman`, and  `yum` (install, remove, update).
- User information utilities: retrieve user ID (`get_uid`) and username (`get_name`), add user (`add_user`) and del user (`del_user`).
- Git operations: clone (`clone`), commit (`commit`), push (`push`), add file (`add`).
- Error handling for common issues like invalid paths, command failuresail, and missing outputs.
- Memory management using Zig's allocator for safe resource handling.

## Installation

Shutil is a static library and can be included in your Zig project by adding the source file to your project and importing it.

1. **Clone or download the library**:
   ```bash
   git clone https://github.com/Neon32eeee/Zig-shutil.git
   ```

2. **Add to your Zig project**:
   Copy the `shutil.zig` file into your project's source directory, or add it as a module in your `build.zig`.

   Example `build.zig`:
   ```zig
   const std = @import("std");

   pub fn build(b: *std.Build) void {
       const target = b.standardTargetOptions(.{});
       const optimize = b.standardOptimizeOption(.{});

       const exe = b.addExecutable(.{
           .name = "myapp",
           .root_source_file = b.path("src/main.zig"),
           .target = target,
           .optimize = optimize,
       });

       // Add Shutil as a module
       exe.addModule("shutil", b.path("path/to/shutil.zig"));

       b.installArtifact(exe);
   }
   ```

3. **Import in your code**:
   ```zig
   const shutil = @import("shutil");
   ```

## Usage

Shutil provides a simple API for executing commands and managing system resources. Below are examples of common operations.

### Running a Shell Command
Execute a shell command and print its output:
```zig
const std = @import("std");
const shutil = @import("shutil");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try shutil.cmd.run(.{}, "ls -l");
}
```

Execute a shell command with root rights:
```zig
const std = @import("std");
const shutil = @import("shutil");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try shutil.cmd.sudo.run(.{}, "ls -l");
}
```

### File Operations
Copy a file:
```zig
try shutil.cmd.cp(.{}, "source.txt", "destination.txt", .{});
```

Create a directory:
```zig
try shutil.cmd.mkdir(.{}, "new_folder", .{});
```

Getting the current path:
```zig
const path = try shutil.cmd.pwd(.{});
```

Remove file and dir:
```zig
try shuitil.cmd.rm(.{}, "text_file", .{});
try shuitil.cmd.rm(.{}, "mydir", .{.dir = true} );
```

### Package Management
Install a package using `apt`:
```zig
try shutil.package.apt.install(allocator, "vim", .{.auto_yes = true});
```

Update package lists using `dnf`:
```zig
try shutil.package.dnf.update(allocator, .{.auto_yes = true});
```

### User Information
Get the current user's ID:
```zig
const uid = try shutil.user.get_uid();
std.debug.print("User ID: {}\n", .{uid});
```

Get the current username:
```zig
const username = try shutil.user.get_name(.{});
defer allocator.free(username);
std.debug.print("Username: {s}\n", .{username});
```

### Users Control
User add
```zig
try shutil.user.add_user(.{}, "user");
```

User del
```zig
try shutil.user.del_user(.{}, "user");
```

### Search Operations
Search command:
```zig
const result = try shutil.cmd.isAvilableCommand(.{}, "ls");
if (result) {
    std.debug.print("You heve command ls!", .{});
} else {
    std.debug.print("You not heve command ls", .{});
}
```

### Git Operations
Clone project
```zig
try shutil.git.clone(allocator, "https://github.com/Neon32eeee/Zig-shutil.git");
```

Commit
```zig
try shutil.git.commit(allocator, "This commit was made using Zig-shutil!");
```

Push
```zig
try shutil.git.push(.{}, "origin", "main");
```

Add file
```zig
try shutil.git.add(.{}, ".");
```

## Error Handling
Shutil defines a custom error set (`ShutilError`) to handle common failure cases:
- `ProcessFailed`: Command execution failed.
- `InvalidPath`: Invalid source or target path for file operations.
- `NoStdout`: No standard output available from the command.
- `CommandNotFound`: Empty or invalid command provided.
- `UserNotFound`: Unable to retrieve user information.
- `InvalidArg`: Incorrectly used argument for a function.

Example of handling errors:
```zig
const result = shutil.cmd.cp(allocator, "", "dest.txt");
if (result) |_| {
    std.debug.print("Copy successful\n", .{});
} else |err| {
    std.debug.print("Error: {}\n", .{err});
}
```

## Contributing
Contributions are welcome! Please submit issues or pull requests to the [GitHub repository](https://github.com/Neon32eeee/Zig-shutil/). Ensure your code follows Zig's style guidelines and includes appropriate tests.
