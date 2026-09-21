#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'Gazelle',
        default => JSON::PP::false,
        order => 85,
        workload_supported => JSON::PP::false,
        workload_unsupported_reason => 'Gazelle does not support keep-alive; this benchmark requires persistent HTTP/1.1 connections',
    });
    exit 0;
}
if ($action eq 'probe') {
    system $^X, '-MGazelle', '-MPlack', '-e', '1';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $^X, '-MGazelle', '-e', 'print $Gazelle::VERSION';
    exit 127;
}
if ($action eq 'settings') {
    print 'max_workers=1, keepalive=unsupported, explicit-only';
    exit 0;
}
if ($action eq 'run') {
    my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
    exec $^X, '-S', 'plackup',
        '-s', 'Gazelle',
        '--host', '127.0.0.1',
        '--port', $port,
        '--max-workers', '1',
        '--max-reqs-per-child', '1000000000',
        '-E', 'production',
        '-a', "$Bin/gazelle-http.psgi";
    die "exec plackup -s Gazelle: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
