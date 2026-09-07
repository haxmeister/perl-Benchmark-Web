#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
my $python = -x "$Bin/.venv/bin/python3" ? "$Bin/.venv/bin/python3" : 'python3';

if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'Python aiohttp',
        default => JSON::PP::true,
        order => 70,
    });
    exit 0;
}
if ($action eq 'probe') {
    system $python, '-c', 'import aiohttp';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $python, '-c', 'import aiohttp; print(aiohttp.__version__)';
    exit 127;
}
if ($action eq 'settings') {
    my $runtime = $python eq 'python3' ? 'system-python3' : 'local-.venv';
    print "aiohttp.web, runtime=$runtime, access_log=off, process=1";
    exit 0;
}
if ($action eq 'run') {
    exec $python, "$Bin/aiohttp-http.py";
    die "exec $python: $!\n";
}

die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
