#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Node.js http', default => JSON::PP::true, order => 50 });
    exit 0;
}
if ($action eq 'probe') {
    system 'node', '--version';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') { exec 'node', '--version'; exit 127; }
if ($action eq 'settings') { print 'runtime=node:http, process=1'; exit 0; }
if ($action eq 'run') {
    exec 'node', "$Bin/node-http.js";
    die "exec node: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
