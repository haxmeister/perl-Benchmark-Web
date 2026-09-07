#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Mojolicious', default => JSON::PP::true, order => 40 });
    exit 0;
}
if ($action eq 'probe') {
    system $^X, '-MMojolicious', '-e', '1';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $^X, '-MMojolicious', '-e', 'print $Mojolicious::VERSION';
    exit 127;
}
if ($action eq 'settings') { print 'daemon=single-process, access_log=off'; exit 0; }
if ($action eq 'run') {
    exec $^X, "$Bin/mojo-http.pl";
    die "exec mojo-http.pl: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
