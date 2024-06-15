const std = @import("std");
const io = std.io;
const path = std.fs.path;
const Client = std.http.Client;
const builtin = @import("builtin");
const JdzGlobalAllocator = @import("jdz_allocator").JdzGlobalAllocator;

const compile = @import("./compile.zig").compile;
const compileBuffer = @import("./compile.zig").compileBuffer;
const MAX_FILE_SIZE = @import("./compile.zig").MAX_FILE_SIZE;

const expect = std.testing.expect;
const expectEqualStrings = std.testing.expectEqualStrings;

const newline = if (builtin.target.os.tag == .windows) "\r\n" else "\n";
const REF_TESTS_DIR = ".reftests";
const TS_VERSION = "5.4.5";
const jdz = JdzGlobalAllocator(.{});

var log_err_count: usize = 0;

pub fn main() !void {
    defer jdz.deinit();
    defer jdz.deinitThread();

    const options = try parseArgs(jdz.allocator());

    var ok_count: usize = 0;
    var skip_count: usize = 0;
    var fail_count: usize = 0;

    const root_dir = if (options.run_reftests) ".reftests" else "src";
    std.debug.print("asdasasdasd\n", .{});
    const cases = try getTestCases(jdz.allocator(), root_dir);
    const root_node = std.Progress.start(.{
        .root_name = "Test",
        .estimated_total_items = cases.len,
    });
    const have_tty = std.io.getStdErr().isTty();

    var leaks: usize = 0;
    for (cases, 0..) |case_file, i| {
        std.testing.allocator_instance = .{};
        defer {
            if (std.testing.allocator_instance.deinit() == .leak) {
                leaks += 1;
            }
        }
        std.testing.log_level = .warn;

        var test_node = root_node.start(case_file.filename, 0);
        std.debug.print("asdasasdasd\n", .{});
        if (!have_tty) {
            std.debug.print("{d}/{d} {s}... ", .{ i + 1, cases.len, case_file.filename });
        }
        std.debug.print("asdasasdasd\n", .{});
        if (runTest(std.heap.page_allocator, root_dir, case_file.filename, case_file.expect_filename)) |_| {
            ok_count += 1;
            test_node.end();
            if (!have_tty) std.debug.print("OK\n", .{});
        } else |err| switch (err) {
            error.SkipZigTest => {
                skip_count += 1;
                if (have_tty) {
                    std.debug.print("{d}/{d} {s}...SKIP\n", .{ i + 1, cases.len, case_file.filename });
                } else {
                    std.debug.print("SKIP\n", .{});
                }
                test_node.end();
            },
            else => {
                fail_count += 1;
                if (have_tty) {
                    std.debug.print("{d}/{d} {s}...FAIL ({s})\n", .{
                        i + 1, cases.len, case_file.filename, @errorName(err),
                    });
                } else {
                    std.debug.print("FAIL ({s})\n", .{@errorName(err)});
                }
                // if (@errorReturnTrace()) |trace| {
                //     std.debug.dumpStackTrace(trace.*);
                // }
                test_node.end();
            },
        }
    }
    root_node.end();
    if (ok_count == cases.len) {
        std.debug.print("All {d} tests passed.\n", .{ok_count});
    } else {
        std.debug.print("{d} passed; {d} skipped; {d} failed.\n", .{ ok_count, skip_count, fail_count });
    }
    if (log_err_count != 0) {
        std.debug.print("{d} errors were logged.\n", .{log_err_count});
    }
    if (leaks != 0) {
        std.debug.print("{d} tests leaked memory.\n", .{leaks});
    }
    if (leaks != 0 or log_err_count != 0 or fail_count != 0) {
        std.process.exit(1);
    }
}

const TestRunnerArgs = struct {
    run_reftests: bool = false,
};

fn parseArgs(allocator: std.mem.Allocator) !TestRunnerArgs {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var result = TestRunnerArgs{};

    for (args) |arg| {
        if (std.mem.eql(u8, arg, "--reference")) {
            result.run_reftests = true;
        }
    }

    return result;
}

fn runTest(alloc: std.mem.Allocator, root_dir: []const u8, case_filepath: []const u8, expect_filepath: []const u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const allocator = arena.allocator();

    std.testing.log_level = .debug;
    var file = try std.fs.cwd().openFile(case_filepath, .{ .mode = .read_only });
    defer file.close();

    const buffer = try file.readToEndAlloc(allocator, MAX_FILE_SIZE);

    const result = try compileBuffer(allocator, case_filepath, buffer);
    var combined_result = std.ArrayList(u8).init(allocator);

    const case_test_path = try path.relative(allocator, root_dir, case_filepath);
    std.mem.replaceScalar(u8, case_test_path, '\\', '/');

    const case_root_dir = path.dirname(case_filepath) orelse unreachable;
    const case_rel_path = try path.relative(allocator, case_root_dir, case_filepath);
    std.mem.replaceScalar(u8, case_rel_path, '\\', '/');

    try std.fmt.format(combined_result.writer(), "//// [{s}] ////" ++ newline ++ newline, .{case_test_path});
    try std.fmt.format(combined_result.writer(), "//// [{s}]" ++ newline, .{case_rel_path});

    try combined_result.appendSlice(buffer);
    try combined_result.appendSlice(newline ++ newline);

    const result_rel_path = try path.relative(allocator, case_root_dir, result.file_name);
    std.mem.replaceScalar(u8, result_rel_path, '\\', '/');

    try std.fmt.format(combined_result.writer(), "//// [{s}]" ++ newline, .{result_rel_path});
    try combined_result.appendSlice(result.output);

    const expect_file = try std.fs.cwd().openFile(expect_filepath, .{ .mode = .read_only });
    const expect_content = try expect_file.readToEndAlloc(allocator, MAX_FILE_SIZE);

    try expect(expect_content.len > 0);
    try expect(combined_result.items.len > 0);
    try expectEqualStrings(expect_content, combined_result.items);
}

const CaseFile = struct {
    filename: []const u8,
    expect_filename: []const u8,
};

fn getTestCases(allocator: std.mem.Allocator, root_dir: []const u8) ![]CaseFile {
    const base_path = try path.join(allocator, &[_][]const u8{ root_dir, "tests" });
    defer allocator.free(base_path);

    const cases_dir = try path.join(allocator, &[_][]const u8{ base_path, "cases", "compiler" });
    defer allocator.free(cases_dir);
    const expects_dir = try path.join(allocator, &[_][]const u8{ base_path, "baselines", "reference" });
    defer allocator.free(expects_dir);

    var dir = try std.fs.cwd().openDir(cases_dir, .{
        .iterate = true,
    });
    defer dir.close();

    var cases = std.ArrayList(CaseFile).init(allocator);
    defer cases.deinit();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        const expect_name = try std.mem.replaceOwned(u8, allocator, entry.name, ".ts", ".js");
        defer allocator.free(expect_name);

        const casefile = CaseFile{
            .filename = try path.join(allocator, &[_][]const u8{
                cases_dir,
                entry.name,
            }),
            .expect_filename = try path.join(allocator, &[_][]const u8{
                expects_dir,
                expect_name,
            }),
        };
        try cases.append(casefile);
    }
    return try cases.toOwnedSlice();
}

fn initRefTestsDir(alloc: std.mem.Allocator) !void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const allocator = arena.allocator();
    var client = Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var arr = std.ArrayList(u8).init(allocator);
    var tarArr = std.ArrayList(u8).init(allocator);
    const url = try std.fmt.allocPrint(allocator, "https://github.com/microsoft/TypeScript/archive/refs/tags/v{s}.tar.gz", .{TS_VERSION});

    std.debug.print("Downloading repository {s} ...\n", .{url});
    const res = try client.fetch(.{
        .method = .GET,
        .response_storage = .{ .dynamic = &arr },
        .max_append_size = 100 * 1024 * 1024 * 1024,
        .location = .{
            .url = url,
        },
    });

    std.debug.print("Status: {}. Unpacking tests to {s}/ directory ...\n", .{ res.status, REF_TESTS_DIR });
    var fb = std.io.fixedBufferStream(arr.items);
    try std.compress.gzip.decompress(fb.reader(), tarArr.writer());

    fb = std.io.fixedBufferStream(tarArr.items);

    var file_name: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var link_name: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    var iter = std.tar.iterator(fb.reader(), .{ .file_name_buffer = &file_name, .link_name_buffer = &link_name });

    const first_file = try iter.next();
    const bytes_to_skip = first_file.?.name.len;
    var output_dir = try std.fs.cwd().openDir(REF_TESTS_DIR, .{});
    defer output_dir.close();

    const file_buffer = try allocator.alloc(u8, MAX_FILE_SIZE);

    var tests_count: u32 = 0;
    while (try iter.next()) |entry| {
        const real_path = entry.name[bytes_to_skip..];
        if (std.mem.startsWith(u8, real_path, "tests/")) {
            switch (entry.kind) {
                .file => {
                    std.debug.print("writing file: {s}\n", .{real_path});
                    const file = try output_dir.createFile(real_path, .{});
                    var file_writer = std.io.bufferedWriter(file.writer());
                    defer file.close();
                    defer file_writer.flush() catch @panic("flush failed");

                    const len = try entry.reader().readAll(file_buffer);

                    try writeAndFixNewlines(file_writer.writer(), file_buffer[0..len]);
                    tests_count += 1;
                },
                .directory => {
                    try output_dir.makePath(real_path);
                },
                else => {},
            }
        }
    }

    std.debug.print("Files extracted: {d}\n", .{tests_count});
}

fn getRefTestCases(alloc: std.mem.Allocator, filter: ?[]const u8) ![]CaseFile {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();

    const allocator = arena.allocator();

    std.fs.cwd().access(REF_TESTS_DIR, .{}) catch |err| {
        if (err == error.FileNotFound) {
            std.debug.print("Creating {s} directory ...\n", .{REF_TESTS_DIR});
            try std.fs.cwd().makePath(REF_TESTS_DIR);
            try initRefTestsDir(allocator);
        } else {
            return err;
        }
    };

    var result = std.ArrayList(CaseFile).init(allocator);
    const cases_dir_path = try path.join(allocator, &[_][]const u8{ REF_TESTS_DIR, "tests", "cases" });
    const expects_dir = try path.join(allocator, &[_][]const u8{ REF_TESTS_DIR, "tests", "baselines", "reference" });

    var cases_dir = try std.fs.cwd().openDir(cases_dir_path, .{
        .iterate = true,
    });
    defer cases_dir.close();

    var walker = try cases_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const is_filter_match = if (filter) |filter_str| std.mem.startsWith(u8, filter_str, entry.path) else true;

            if (is_filter_match) {
                const expect_name = try std.mem.replaceOwned(u8, allocator, entry.basename, ".ts", ".js");
                defer allocator.free(expect_name);

                const basename_path = path.relative(allocator, cases_dir_path, entry.path);
                try result.append(.{
                    .filename = try path.join(allocator, &[_][]const u8{ cases_dir_path, basename_path }),
                    .expect_filename = try path.join(allocator, &[_][]const u8{ expects_dir, expect_name }),
                });
            }
        }
    }

    return result.toOwnedSlice();
}

fn writeAndFixNewlines(writer: anytype, buffer: []const u8) !void {
    for (0..buffer.len) |i| {
        if (should_replace_newline(buffer, i)) {
            try writer.writeAll(newline);
        } else {
            try writer.writeByte(buffer[i]);
        }
    }
}

fn should_replace_newline(buffer: []const u8, i: usize) bool {
    if (builtin.target.os.tag == .windows) {
        return buffer[i] == '\n' and i > 0 and buffer[i - 1] != '\r';
    } else {
        return buffer[i] == '\n' and i > 0 and buffer[i - 1] == '\r';
    }
}