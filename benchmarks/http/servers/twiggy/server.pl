#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Twiggy/AnyEvent', default => JSON::PP::false, order => 80 });
    exit 0;
}
if ($action eq 'probe') {
    system $^X, '-MTwiggy', '-e', '1';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec $^X, '-MTwiggy', '-e', 'print $Twiggy::VERSION';
    exit 127;
}
if ($action eq 'settings') { print 'Twiggy::Server, process=1, explicit-only'; exit 0; }
if ($action eq 'run') {
    exec $^X, "$Bin/twiggy-http.pl";
    die "exec twiggy-http.pl: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
