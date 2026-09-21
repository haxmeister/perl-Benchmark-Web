#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Loop;
use Linux::Event::WebSocket::Server;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $ack = '{"ok":true}';

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::WebSocket::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => $port,
    max_message_size => 32 * 1024 * 1024,
    on_message => sub ($ws, $payload, $type) {
        die "benchmark received non-text WebSocket message\n"
            if $type ne 'text';
        die "benchmark received malformed application request\n"
            if substr($payload, 0, 6) ne '{"op":';
        $ws->send_text($ack);
    },
);
$loop->run;
