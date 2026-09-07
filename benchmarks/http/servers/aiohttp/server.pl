#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Python aiohttp', default => JSON::PP::true, order => 70 });
    exit 0;
}
if ($action eq 'probe') {
    system 'python3', '-c', 'import aiohttp';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec 'python3', '-c', 'import aiohttp; print(aiohttp.__version__)';
    exit 127;
}
if ($action eq 'settings') { print 'aiohttp.web, access_log=off, process=1'; exit 0; }
if ($action eq 'run') {
    exec 'python3', "$Bin/aiohttp-http.py";
    die "exec python3: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
