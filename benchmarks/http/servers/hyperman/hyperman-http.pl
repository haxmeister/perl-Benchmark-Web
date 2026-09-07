#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Hyperman;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $request_body_bytes = 0 + ($ENV{BENCH_REQUEST_BODY_BYTES} // 0);
my $payload = 'x' x $response_bytes;

my $app = sub ($env) {
    my $remaining = 0 + ($env->{CONTENT_LENGTH} // 0);
    my $input = $env->{'psgi.input'};

    while ($remaining > 0) {
        my $want = $remaining > 65_536 ? 65_536 : $remaining;
        my $chunk = '';
        my $n = $input->read($chunk, $want);
        die "short benchmark request body\n"
            if !defined($n) || $n <= 0;
        $remaining -= $n;
    }

    return [
        200,
        [
            'Content-Type'   => 'application/octet-stream',
            'Content-Length' => length($payload),
        ],
        [$payload],
    ];
};

my %run = (
    app      => $app,
    host     => '127.0.0.1',
    port     => 0 + $port,
    workers  => 1,
    compress => 0,
);

$run{max_body} = $request_body_bytes + 65_536
    if $request_body_bytes + 65_536 > 16 * 1024 * 1024;

Hyperman->run(%run);
