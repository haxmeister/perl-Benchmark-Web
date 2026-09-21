#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Mojolicious::Lite;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $ack = '{"ok":true}';

app->log->level('fatal');

websocket '/application' => sub ($c) {
    $c->inactivity_timeout(0);
    $c->on(message => sub ($c, $payload) {
        die "benchmark received malformed application request\n"
            if substr($payload, 0, 6) ne '{"op":';
        $c->send($ack);
    });
};

app->start('daemon', '-l', "http://127.0.0.1:$port");
