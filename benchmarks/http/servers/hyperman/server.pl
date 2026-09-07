#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Hyperman', default => JSON::PP::true, order => 20 });
    exit 0;
}
if ($action eq 'probe') {
    system $^X, '-MHyperman', '-e', '1';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $^X, '-MHyperman', '-e', 'print $Hyperman::VERSION';
    exit 127;
}
if ($action eq 'settings') { print 'workers=1, compression=off'; exit 0; }
if ($action eq 'run') {
    exec $^X, "$Bin/hyperman-http.pl";
    die "exec hyperman-http.pl: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
