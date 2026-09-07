#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Feersum::Runner;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $payload = 'x' x $response_bytes;

my $runner = Feersum::Runner->new(
    listen              => ["127.0.0.1:$port"],
    pre_fork            => 0,
    keepalive           => 1,
    max_connection_reqs => 0,
    quiet               => 1,
);

$runner->run(sub ($request) {
    my $remaining = 0 + ($request->content_length // 0);
    if ($remaining > 0) {
        my $input = $request->input;
        die "missing benchmark request body\n" if !defined $input;
        while ($remaining > 0) {
            my $want = $remaining > 65_536 ? 65_536 : $remaining;
            my $chunk = '';
            my $n = $input->read($chunk, $want);
            die "short benchmark request body\n"
                if !defined($n) || $n <= 0;
            $remaining -= $n;
        }
    }

    $request->send_response(
        200,
        [
            'Content-Type'   => 'application/octet-stream',
            'Content-Length' => length($payload),
        ],
        \$payload,
    );
    return;
});
