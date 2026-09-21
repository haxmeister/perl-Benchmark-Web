#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'Node.js ws',
        default => JSON::PP::true,
        order => 30,
    });
    exit 0;
}
if ($action eq 'probe') {
    system 'node', "$Bin/probe.mjs";
    exit($? == 0 ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0 }
if ($action eq 'version') {
    my $node = capture('node', '--version') // 'node unknown';
    my $ws = capture('node', '-e', q{console.log(require('ws/package.json').version)}) // 'ws unknown';
    print "$node, ws $ws";
    exit 0;
}
if ($action eq 'settings') {
    print 'runtime=node, library=ws, process=1, permessage-deflate=off';
    exit 0;
}
if ($action eq 'run') {
    exec 'node', "$Bin/node-ws.mjs";
    die "exec node: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";

sub capture (@command) {
    open my $fh, '-|', @command or return undef;
    local $/;
    my $text = <$fh> // '';
    close $fh or return undef;
    $text =~ s/\s+\z//;
    return $text;
}
