#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'Starman',
        default => JSON::PP::false,
        order => 75,
        max_persistent_connections => 1,
    });
    exit 0;
}
if ($action eq 'probe') {
    system $^X, '-MStarman', '-MPlack', '-e', '1';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $^X, '-MStarman', '-e', 'print $Starman::VERSION';
    exit 127;
}
if ($action eq 'settings') {
    print 'workers=1, prefork-master=yes, keepalive=on, max_persistent_connections=1, explicit-only';
    exit 0;
}
if ($action eq 'run') {
    my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
    exec $^X, '-S', 'starman',
        '--listen', "127.0.0.1:$port",
        '--workers', '1',
        '--max-requests', '1000000000',
        '--preload-app',
        "$Bin/starman-http.psgi";
    die "exec starman: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
