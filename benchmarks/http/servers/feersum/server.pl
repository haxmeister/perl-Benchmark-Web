#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Feersum', default => JSON::PP::true, order => 30 });
    exit 0;
}
if ($action eq 'probe') {
    system $^X, '-MFeersum::Runner', '-e', '1';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $^X, '-MFeersum', '-e', 'print $Feersum::VERSION';
    exit 127;
}
if ($action eq 'settings') { print 'prefork=off, keepalive=on, max_connection_reqs=unlimited'; exit 0; }
if ($action eq 'run') {
    exec $^X, "$Bin/feersum-http.pl";
    die "exec feersum-http.pl: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
