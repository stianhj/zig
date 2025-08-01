//! To get started, run this tool with no args and read the help message.
//!
//! The build systems of glibc, musl, FreeBSD, and NetBSD require specifying a single target
//! architecture. Meanwhile, Zig supports out-of-the-box cross compilation for
//! every target. So the process to create libc headers that Zig ships is to use
//! this tool.
//!
//! First, use the glibc, musl, FreeBSD, and NetBSD build systems to create installations of all the
//! targets in the `glibc_targets`, `musl_targets`, `freebsd_targets`, and `netbsd_targets`
//! variables. Next, run this tool to create a new directory which puts .h files into
//! <arch> subdirectories, with `generic` being files that apply to all architectures.
//! You'll then have to manually update Zig source repo with these new files.

const std = @import("std");
const Arch = std.Target.Cpu.Arch;
const Abi = std.Target.Abi;
const OsTag = std.Target.Os.Tag;
const assert = std.debug.assert;
const Blake3 = std.crypto.hash.Blake3;

const LibCTarget = struct {
    arch: Arch,
    abi: Abi,
    dest: ?[]const u8 = null,
};

const glibc_targets = [_]LibCTarget{
    .{ .arch = .arc, .abi = .gnu },
    .{ .arch = .arm, .abi = .gnueabi, .dest = "arm-linux-gnu" },
    .{ .arch = .arm, .abi = .gnueabihf, .dest = "arm-linux-gnu" },
    .{ .arch = .armeb, .abi = .gnueabi, .dest = "arm-linux-gnu" },
    .{ .arch = .armeb, .abi = .gnueabihf, .dest = "arm-linux-gnu" },
    .{ .arch = .aarch64, .abi = .gnu, .dest = "aarch64-linux-gnu" },
    .{ .arch = .aarch64_be, .abi = .gnu, .dest = "aarch64-linux-gnu" },
    .{ .arch = .csky, .abi = .gnueabi, .dest = "csky-linux-gnu" },
    .{ .arch = .csky, .abi = .gnueabihf, .dest = "csky-linux-gnu" },
    .{ .arch = .loongarch64, .abi = .gnu, .dest = "loongarch-linux-gnu" },
    .{ .arch = .loongarch64, .abi = .gnusf, .dest = "loongarch-linux-gnu" },
    .{ .arch = .m68k, .abi = .gnu },
    .{ .arch = .mips, .abi = .gnueabi, .dest = "mips-linux-gnu" },
    .{ .arch = .mips, .abi = .gnueabihf, .dest = "mips-linux-gnu" },
    .{ .arch = .mipsel, .abi = .gnueabi, .dest = "mips-linux-gnu" },
    .{ .arch = .mipsel, .abi = .gnueabihf, .dest = "mips-linux-gnu" },
    .{ .arch = .mips64, .abi = .gnuabi64, .dest = "mips-linux-gnu" },
    .{ .arch = .mips64, .abi = .gnuabin32, .dest = "mips-linux-gnu" },
    .{ .arch = .mips64el, .abi = .gnuabi64, .dest = "mips-linux-gnu" },
    .{ .arch = .mips64el, .abi = .gnuabin32, .dest = "mips-linux-gnu" },
    .{ .arch = .powerpc, .abi = .gnueabi, .dest = "powerpc-linux-gnu" },
    .{ .arch = .powerpc, .abi = .gnueabihf, .dest = "powerpc-linux-gnu" },
    .{ .arch = .powerpc64, .abi = .gnu, .dest = "powerpc-linux-gnu" },
    .{ .arch = .powerpc64le, .abi = .gnu, .dest = "powerpc-linux-gnu" },
    .{ .arch = .riscv32, .abi = .gnu, .dest = "riscv-linux-gnu" },
    .{ .arch = .riscv64, .abi = .gnu, .dest = "riscv-linux-gnu" },
    .{ .arch = .s390x, .abi = .gnu },
    .{ .arch = .sparc, .abi = .gnu, .dest = "sparc-linux-gnu" },
    .{ .arch = .sparc64, .abi = .gnu, .dest = "sparc-linux-gnu" },
    .{ .arch = .x86, .abi = .gnu, .dest = "x86-linux-gnu" },
    .{ .arch = .x86_64, .abi = .gnu, .dest = "x86-linux-gnu" },
    .{ .arch = .x86_64, .abi = .gnux32, .dest = "x86-linux-gnu" },
};

const musl_targets = [_]LibCTarget{
    .{ .arch = .arm, .abi = .musl },
    .{ .arch = .aarch64, .abi = .musl },
    .{ .arch = .hexagon, .abi = .musl },
    .{ .arch = .loongarch64, .abi = .musl },
    .{ .arch = .m68k, .abi = .musl },
    .{ .arch = .mips, .abi = .musl },
    .{ .arch = .mips64, .abi = .musl },
    .{ .arch = .mips64, .abi = .muslabin32 },
    .{ .arch = .powerpc, .abi = .musl },
    .{ .arch = .powerpc64, .abi = .musl },
    .{ .arch = .riscv32, .abi = .musl },
    .{ .arch = .riscv64, .abi = .musl },
    .{ .arch = .s390x, .abi = .musl },
    .{ .arch = .x86, .abi = .musl },
    .{ .arch = .x86_64, .abi = .musl },
    .{ .arch = .x86_64, .abi = .muslx32 },
};

const freebsd_targets = [_]LibCTarget{
    .{ .arch = .arm, .abi = .eabihf },
    .{ .arch = .aarch64, .abi = .none },
    .{ .arch = .powerpc, .abi = .eabihf },
    .{ .arch = .powerpc64, .abi = .none },
    .{ .arch = .riscv64, .abi = .none },
    .{ .arch = .x86, .abi = .none },
    .{ .arch = .x86_64, .abi = .none },
};

const netbsd_targets = [_]LibCTarget{
    .{ .arch = .arm, .abi = .eabi, .dest = "arm-netbsd-eabi" },
    .{ .arch = .arm, .abi = .eabihf, .dest = "arm-netbsd-eabi" },
    .{ .arch = .aarch64, .abi = .none },
    .{ .arch = .m68k, .abi = .none },
    .{ .arch = .mips, .abi = .eabi, .dest = "mips-netbsd-eabi" },
    .{ .arch = .mips, .abi = .eabihf, .dest = "mips-netbsd-eabi" },
    .{ .arch = .powerpc, .abi = .eabi, .dest = "powerpc-netbsd-eabi" },
    .{ .arch = .powerpc, .abi = .eabihf, .dest = "powerpc-netbsd-eabi" },
    .{ .arch = .sparc, .abi = .none },
    .{ .arch = .sparc64, .abi = .none },
    .{ .arch = .x86, .abi = .none },
    .{ .arch = .x86_64, .abi = .none },
};

const Contents = struct {
    bytes: []const u8,
    hit_count: usize,
    hash: []const u8,
    is_generic: bool,

    fn hitCountLessThan(context: void, lhs: *const Contents, rhs: *const Contents) bool {
        _ = context;
        return lhs.hit_count < rhs.hit_count;
    }
};

const HashToContents = std.StringHashMap(Contents);
const TargetToHash = std.StringArrayHashMap([]const u8);
const PathTable = std.StringHashMap(*TargetToHash);

const LibCVendor = enum {
    musl,
    glibc,
    freebsd,
    netbsd,
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    var search_paths = std.ArrayList([]const u8).init(allocator);
    var opt_out_dir: ?[]const u8 = null;
    var opt_abi: ?[]const u8 = null;

    var arg_i: usize = 1;
    while (arg_i < args.len) : (arg_i += 1) {
        if (std.mem.eql(u8, args[arg_i], "--help"))
            usageAndExit(args[0]);
        if (arg_i + 1 >= args.len) {
            std.debug.print("expected argument after '{s}'\n", .{args[arg_i]});
            usageAndExit(args[0]);
        }

        if (std.mem.eql(u8, args[arg_i], "--search-path")) {
            try search_paths.append(args[arg_i + 1]);
        } else if (std.mem.eql(u8, args[arg_i], "--out")) {
            assert(opt_out_dir == null);
            opt_out_dir = args[arg_i + 1];
        } else if (std.mem.eql(u8, args[arg_i], "--abi")) {
            assert(opt_abi == null);
            opt_abi = args[arg_i + 1];
        } else {
            std.debug.print("unrecognized argument: {s}\n", .{args[arg_i]});
            usageAndExit(args[0]);
        }

        arg_i += 1;
    }

    const out_dir = opt_out_dir orelse usageAndExit(args[0]);
    const abi_name = opt_abi orelse usageAndExit(args[0]);
    const vendor = std.meta.stringToEnum(LibCVendor, abi_name) orelse {
        std.debug.print("unrecognized C ABI: {s}\n", .{abi_name});
        usageAndExit(args[0]);
    };

    const generic_name = try std.fmt.allocPrint(allocator, "generic-{s}", .{abi_name});
    const libc_targets = switch (vendor) {
        .glibc => &glibc_targets,
        .musl => &musl_targets,
        .freebsd => &freebsd_targets,
        .netbsd => &netbsd_targets,
    };

    var path_table = PathTable.init(allocator);
    var hash_to_contents = HashToContents.init(allocator);
    var max_bytes_saved: usize = 0;
    var total_bytes: usize = 0;

    var hasher = Blake3.init(.{});

    for (libc_targets) |libc_target| {
        const libc_dir = switch (vendor) {
            .glibc => try std.zig.target.glibcRuntimeTriple(allocator, libc_target.arch, .linux, libc_target.abi),
            .musl => std.zig.target.muslArchName(libc_target.arch, libc_target.abi),
            .freebsd => switch (libc_target.arch) {
                .arm => "armv7",
                .x86 => "i386",
                .x86_64 => "amd64",

                .aarch64,
                .powerpc,
                .powerpc64,
                .riscv64,
                => |a| @tagName(a),

                else => unreachable,
            },
            .netbsd => switch (libc_target.arch) {
                .arm => if (libc_target.abi == .eabihf) "evbarmv7hf" else "evbarmv7",
                .aarch64 => "evbarm64",
                .m68k => "mac68k",
                .mips => if (libc_target.abi == .eabihf) "evbmips" else "evbmipssf",
                .powerpc => if (libc_target.abi == .eabihf) "evbppc" else "evbppcsf",
                .x86 => "i386",
                .x86_64 => "amd64",

                .sparc,
                .sparc64,
                => |a| @tagName(a),

                else => unreachable,
            },
        };

        const dest_target = if (libc_target.dest) |dest| dest else try std.fmt.allocPrint(allocator, "{s}-{s}-{s}", .{
            @tagName(libc_target.arch),
            switch (vendor) {
                .musl, .glibc => "linux",
                .freebsd => "freebsd",
                .netbsd => "netbsd",
            },
            @tagName(libc_target.abi),
        });

        search: for (search_paths.items) |search_path| {
            const sub_path = switch (vendor) {
                .glibc,
                .freebsd,
                .netbsd,
                => &[_][]const u8{ search_path, libc_dir, "usr", "include" },
                .musl => &[_][]const u8{ search_path, libc_dir, "usr", "local", "musl", "include" },
            };
            const target_include_dir = try std.fs.path.join(allocator, sub_path);
            var dir_stack = std.ArrayList([]const u8).init(allocator);
            try dir_stack.append(target_include_dir);

            while (dir_stack.pop()) |full_dir_name| {
                var dir = std.fs.cwd().openDir(full_dir_name, .{ .iterate = true }) catch |err| switch (err) {
                    error.FileNotFound => continue :search,
                    error.AccessDenied => continue :search,
                    else => return err,
                };
                defer dir.close();

                var dir_it = dir.iterate();

                while (try dir_it.next()) |entry| {
                    const full_path = try std.fs.path.join(allocator, &[_][]const u8{ full_dir_name, entry.name });
                    switch (entry.kind) {
                        .directory => try dir_stack.append(full_path),
                        .file, .sym_link => {
                            const rel_path = try std.fs.path.relative(allocator, target_include_dir, full_path);
                            const max_size = 2 * 1024 * 1024 * 1024;
                            const raw_bytes = try std.fs.cwd().readFileAlloc(allocator, full_path, max_size);
                            const trimmed = std.mem.trim(u8, raw_bytes, " \r\n\t");
                            total_bytes += raw_bytes.len;
                            const hash = try allocator.alloc(u8, 32);
                            hasher = Blake3.init(.{});
                            hasher.update(rel_path);
                            hasher.update(trimmed);
                            hasher.final(hash);
                            const gop = try hash_to_contents.getOrPut(hash);
                            if (gop.found_existing) {
                                max_bytes_saved += raw_bytes.len;
                                gop.value_ptr.hit_count += 1;
                                std.debug.print("duplicate: {s} {s} ({B})\n", .{
                                    libc_dir,
                                    rel_path,
                                    raw_bytes.len,
                                });
                            } else {
                                gop.value_ptr.* = Contents{
                                    .bytes = trimmed,
                                    .hit_count = 1,
                                    .hash = hash,
                                    .is_generic = false,
                                };
                            }
                            const path_gop = try path_table.getOrPut(rel_path);
                            const target_to_hash = if (path_gop.found_existing) path_gop.value_ptr.* else blk: {
                                const ptr = try allocator.create(TargetToHash);
                                ptr.* = TargetToHash.init(allocator);
                                path_gop.value_ptr.* = ptr;
                                break :blk ptr;
                            };
                            // When `dest` is set, there are a few rare cases where we expect to overwrite a header. For
                            // example, `bits/long-double.h` differs very slightly between `powerpc64le-linux-gnu` and
                            // other `powerpc*-linux-gnu` targets, and we unify those targets as `powerpc-linux-gnu`. In
                            // such cases, we manually patch the affected header after processing, so it's fine that
                            // only one header wins here.
                            if (libc_target.dest != null) {
                                const hash_gop = try target_to_hash.getOrPut(dest_target);
                                if (hash_gop.found_existing) std.debug.print("overwrote: {s} {s} {s}\n", .{
                                    libc_dir,
                                    rel_path,
                                    dest_target,
                                }) else hash_gop.value_ptr.* = hash;
                            } else {
                                try target_to_hash.putNoClobber(dest_target, hash);
                            }
                        },
                        else => std.debug.print("warning: weird file: {s}\n", .{full_path}),
                    }
                }
            }
            break;
        } else {
            std.debug.print("warning: libc target not found: {s}\n", .{libc_dir});
        }
    }
    std.debug.print("summary: {B} could be reduced to {B}\n", .{
        total_bytes,
        total_bytes - max_bytes_saved,
    });
    try std.fs.cwd().makePath(out_dir);

    var missed_opportunity_bytes: usize = 0;
    // iterate path_table. for each path, put all the hashes into a list. sort by hit_count.
    // the hash with the highest hit_count gets to be the "generic" one. everybody else
    // gets their header in a separate arch directory.
    var path_it = path_table.iterator();
    while (path_it.next()) |path_kv| {
        var contents_list = std.ArrayList(*Contents).init(allocator);
        {
            var hash_it = path_kv.value_ptr.*.iterator();
            while (hash_it.next()) |hash_kv| {
                const contents = hash_to_contents.getPtr(hash_kv.value_ptr.*).?;
                try contents_list.append(contents);
            }
        }
        std.mem.sort(*Contents, contents_list.items, {}, Contents.hitCountLessThan);
        const best_contents = contents_list.pop().?;
        if (best_contents.hit_count > 1) {
            // worth it to make it generic
            const full_path = try std.fs.path.join(allocator, &[_][]const u8{ out_dir, generic_name, path_kv.key_ptr.* });
            try std.fs.cwd().makePath(std.fs.path.dirname(full_path).?);
            try std.fs.cwd().writeFile(.{ .sub_path = full_path, .data = best_contents.bytes });
            best_contents.is_generic = true;
            while (contents_list.pop()) |contender| {
                if (contender.hit_count > 1) {
                    const this_missed_bytes = contender.hit_count * contender.bytes.len;
                    missed_opportunity_bytes += this_missed_bytes;
                    std.debug.print("Missed opportunity ({B}): {s}\n", .{
                        this_missed_bytes,
                        path_kv.key_ptr.*,
                    });
                } else break;
            }
        }
        var hash_it = path_kv.value_ptr.*.iterator();
        while (hash_it.next()) |hash_kv| {
            const contents = hash_to_contents.get(hash_kv.value_ptr.*).?;
            if (contents.is_generic) continue;

            const dest_target = hash_kv.key_ptr.*;
            const full_path = try std.fs.path.join(allocator, &[_][]const u8{ out_dir, dest_target, path_kv.key_ptr.* });
            try std.fs.cwd().makePath(std.fs.path.dirname(full_path).?);
            try std.fs.cwd().writeFile(.{ .sub_path = full_path, .data = contents.bytes });
        }
    }
}

fn usageAndExit(arg0: []const u8) noreturn {
    std.debug.print("Usage: {s} [--search-path <dir>] --out <dir> --abi <name>\n", .{arg0});
    std.debug.print("--search-path can be used any number of times.\n", .{});
    std.debug.print("    subdirectories of search paths look like, e.g. x86_64-linux-gnu\n", .{});
    std.debug.print("--out is a dir that will be created, and populated with the results\n", .{});
    std.debug.print("--abi is either glibc, musl, freebsd, or netbsd\n", .{});
    std.process.exit(1);
}
