# Shutil - Simplified Command Execution Library for Zig

Shutil is a lightweight, open-source static library for Zig that simplifies command-line operations and process execution. It provides a convenient interface for running shell commands, managing files, handling package management tasks across Linux package managers (`apt`, `dnf`, `pacman`, `yum`), and performing Git operations. The library also includes utilities for retrieving and managing user information.

## Features

- Execute shell commands with `cmd.run` and root commands with `cmd.sudo.run`.
- File operations: copy (`cp`), move (`mv`), create directories (`mkdir`), create files (`touch`), display file contents (`cat`), echo text (`echo`), get current path (`pwd`), remove files or directories (`rm`), find files (`find`), search text in files (`grep`).
- Check command availability with `isAvailableCommand`.
- Package management for `apt`, `dnf`, `pacman`, and `yum` (install, remove, update).
- User management: retrieve user ID (`getUID`), username (`getName`), add user (`addUser`), delete user (`delUser`).
- Git operations: clone (`clone`), commit (`commit`), push (`push`), add files (`add`), pull (`pull`).
- Path options: getting real path(`realpath`), getting fail name without a path(`basename`), getting path to file(`dirname`), checking for path existence(`exists`), directory check(`isDir`), file check(`isFile`), getting size file(`size`).
- Error handling for issues like invalid paths, command failures, missing outputs, and invalid arguments.
- The net opiration: get site to url(`curl`), get file on site(`wget`).
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

Shutil provides a simple API for executing commands and managing system resources. Most functions accept a `CmdSettings` struct with the following fields:
- `allocator`: Memory allocator (defaults to `std.heap.page_allocator`).
- `max_buffer_size`: Maximum buffer size for command output (defaults to 4096 bytes).

Below are examples of common operations with detailed flag descriptions.

### Running a Shell Command
Execute a shell command and print its output:
```zig
const std = @import("std");
const shutil = @import("shutil");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    try shutil.cmd.run(.{ .allocator = allocator }, "ls -l");
}
```

Execute a shell command with root privileges:
```zig
try shutil.cmd.sudo.run(.{ .allocator = allocator }, "apt update");
```

### File Operations
Copy a file:
```zig
try shutil.cmd.cp(.{}, "source.txt", "destination.txt", .{ .force = true });
```
- Flags:
  - `force`: Overwrites the destination file if it exists (`-f`).

Move a file or directory:
```zig
try shutil.cmd.mv(.{}, "source.txt", "dest.txt", .{ .force = true });
```
- Flags:
  - `force`: Overwrites the destination if it exists (`-f`).

Create a directory:
```zig
try shutil.cmd.mkdir(.{}, "new_folder", .{ .parents = true });
```
- Flags:
  - `parents`: Creates parent directories as needed (`-p`).

Create an empty file:
```zig
try shutil.cmd.touch(.{}, "newfile.txt");
```

Display file contents:
```zig
try shutil.cmd.cat(.{}, "file.txt");
```

Return file contents:
```zig
_ = try shutil.cmd.catReturn(.{}, "file.txt");
```

Echo text to stdout:
```zig
try shutil.cmd.echo(.{}, "Hello, World!");
```

Get the current working directory:
```zig
const path = try shutil.cmd.pwd(.{});
defer allocator.free(path);
std.debug.print("Current path: {s}\n", .{path});
```

Remove a file or directory:
```zig
try shutil.cmd.rm(.{}, "file.txt", .{ .force = true });
try shutil.cmd.rm(.{}, "mydir", .{ .dir = true, .verbose = true });
```
- Flags:
  - `dir`: Removes directories recursively (`-r`).
  - `force`: Suppresses errors if the file doesn't exist (`-f`).
  - `verbose`: Prints removed files/directories (`-v`).

Search for files or directories:
```zig
const results = try shutil.cmd.find(.{}, "*.txt", .{ .type = .file });
defer allocator.free(results);
std.debug.print("Found: {s}\n", .{results});
```
- Flags:
  - `type`: Filters by `file` or `dir` (`-type f` or `-type d`).
  - `maxdepth`: Limits search based on value.

Search for text in a file:
```zig
const results = try shutil.cmd.grep(.{}, "error", "log.txt");
defer allocator.free(results);
std.debug.print("Matches: {s}\n", .{results});
```

Check if a command is available:
```zig
const exists = try shutil.cmd.isAvailableCommand(.{}, "ls");
std.debug.print("Command ls exists: {}\n", .{exists});
```

### Package Management
Install a package using `apt`:
```zig
try shutil.package.apt.install(.{}, "vim", .{ .auto_yes = true });
```
- Flags:
  - `auto_yes`: Automatically confirms installation (`-y`).

Remove a package using `dnf`:
```zig
try shutil.package.dnf.remove(.{}, "vim", .{ .auto_yes = true });
```
- Flags:
  - `auto_yes`: Automatically confirms removal (`-y`).

Update package lists using `pacman`:
```zig
try shutil.package.pacman.update(.{}, .{ .auto_yes = true });
```
- Flags:
  - `auto_yes`: Automatically confirms updates (`--noconfirm` for pacman, `-y` for others).

Check if a package manager is available:
```zig
const apt_available = try shutil.package.apt.isAvailable(.{});
std.debug.print("Apt available: {}\n", .{apt_available});
```

### User Management
Get the current user's ID:
```zig
const uid = try shutil.user.getUID();
std.debug.print("User ID: {}\n", .{uid});
```

Get the current username:
```zig
const username = try shutil.user.getName(.{});
defer allocator.free(username);
std.debug.print("Username: {s}\n", .{username});
```

Add a new user:
```zig
try shutil.user.addUser(.{}, "newuser");
```

Delete a user:
```zig
try shutil.user.delUser(.{}, "newuser");
```

Get user info:
```zig
const user_info = try shutil.user.getUserInfo(.{}, "user");
std.debug.print("User info: {s}, {s}, {s}\n", .{user_info.uid, user_info.home, user_info.shell});

```

### Git Operations
Clone a repository:
```zig
try shutil.git.clone(.{}, "https://github.com/Neon32eeee/Zig-shutil.git");
```

Add files to a commit:
```zig
try shutil.git.add(.{}, ".");
```

Commit changes:
```zig
try shutil.git.commit(.{}, "Update project files");
```

Push to a repository:
```zig
try shutil.git.push(.{}, "origin", "main");
```

Pull from a repository:
```zig
try shutil.git.pull(.{}, "origin", "main");
```

### Path Operations
Getting real path:
```zig
_ = try shutil.path.realpath(.{}, "../../myfile");
```

Getting file name without a path:
```zig
_ try shutil.path.basename(.{}, "src/namespace/path.zig");
```

Getting path to file:
```zig
_ try shutil.path.dirname(.{}, "build.zig");
```

Checking for path existence:
```zig
if (try shutil.path.exists(.{}, "zig-out/.zig-cache")) {
  std.debug.print("Path existence!", .{});
}
```

Directory check:
```zig
if (try shutil.path.isDir(.{}, "zig-out")) {
  std.debug.print("This is a directory!", .{});
}
```

File check:
```zig
if (try shutil.path.isFile(.{}, "build.zid")) {
  std.debug.print("This is a file!", .{});
}
```

Getting size file:
```zig
_ = try shutil.path.size(.{}, "src/main.zig");
```

Getting permissions file:
```zig
_ = try shutil.path.permisson(.{}, "src/main.zig");
```

### The net operation
Get site to url:
```zig
const info_site = try shutil.net.curl(.{}, "https://localhost:8080");
```

Get file on site:
```zig
try shutil.net.wget(.{}, "https://github.com/Neon32eeee/Zig-shutil/archive/refs/heads/main.zip")
```

## Error Handling
Shutil defines a custom error set (`ShutilError`) for common failure cases:
- `ProcessFailed`: Command execution failed.
- `InvalidPath`: Invalid source or target path.
- `NoStdout`: No standard output available.
- `CommandNotFound`: Empty or invalid command.
- `UserNotFound`: Unable to retrieve user information.
- `InvalidArg`: Incorrectly used argument.

Example of handling errors:
```zig
const result = shutil.cmd.cp(.{}, "nonexistent.txt", "dest.txt", .{});
if (result) |_| {
    std.debug.print("Copy successful\n", .{});
} else |err| {
    std.debug.print("Error: {}\n", .{err});
}
```

## Contributing
Contributions are welcome! Please submit issues or pull requests to the [GitHub repository](https://github.com/Neon32eeee/Zig-shutil/). Ensure your code follows Zig's style guidelines and includes appropriate tests.