#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
my $binary = '/tmp/benchmark-web-http-go-' . getppid();
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Go net/http', default => JSON::PP::true, order => 60 });
    exit 0;
}
if ($action eq 'probe') {
    system 'go', 'version';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare') {
    system 'go', 'build', '-o', $binary, "$Bin/go-http.go";
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'cleanup') { unlink $binary if -e $binary; exit 0; }
if ($action eq 'version') { exec 'go', 'version'; exit 127; }
if ($action eq 'settings') { print 'GOMAXPROCS=1'; exit 0; }
if ($action eq 'run') {
    $ENV{GOMAXPROCS} = 1;
    exec $binary;
    die "exec $binary: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
