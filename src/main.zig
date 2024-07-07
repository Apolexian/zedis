const clap = @import("clap");
const std = @import("std");

const debug = std.debug;
const io = std.io;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-a, --address <STR>        An option parameter which can be specified multiple times.
        \\
    );

    const parsers = comptime .{
        .STR = clap.parsers.string,
    };

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, parsers, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        diag.report(io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        debug.print("TODO\n", .{});
        std.process.exit(0);
    }

    if (res.args.address) |a| {
        var server = try setupServer(a);
        defer server.deinit();
        var conn = try server.accept();
        var buf: [100]u8 = undefined;
        const read = try conn.stream.readAll(&buf);
        debug.print("read = {s}\n", .{buf[0..read]});
        defer conn.close();

        std.process.exit(0);
    }

    debug.print("TODO\n", .{});
}

fn setupServer(a: []const u8) !std.net.Server {
    const stdAddress = std.net.Address;
    const address = try stdAddress.parseIp(a, 8080);
    const options = stdAddress.ListenOptions{};
    return try stdAddress.listen(address, options);
}
