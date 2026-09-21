#!/usr/bin/env perl
use Cwd ();
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
my $binary = '/tmp/benchmark-web-websocket-gorilla-' . getppid();

if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'Go gorilla/websocket',
        default => JSON::PP::true,
        order => 40,
    });
    exit 0;
}
if ($action eq 'probe') {
    system 'go', 'version';
    exit($? == 0 ? 0 : 1);
}
if ($action eq 'prepare') {
    my $old = Cwd::getcwd();
    chdir $Bin or die "chdir $Bin: $!\n";
    system 'go', 'mod', 'tidy';
    my $status = $?;
    if ($status == 0) {
        system 'go', 'build', '-o', $binary, '.';
        $status = $?;
    }
    chdir $old or die "chdir $old: $!\n";
    exit($status == 0 ? 0 : 1);
}
if ($action eq 'cleanup') {
    unlink $binary if -e $binary;
    exit 0;
}
if ($action eq 'version') {
    exec 'go', 'version';
    exit 127;
}
if ($action eq 'settings') {
    print 'GOMAXPROCS=1, gorilla/websocket=1.5.3';
    exit 0;
}
if ($action eq 'run') {
    $ENV{GOMAXPROCS} = 1;
    exec $binary;
    die "exec $binary: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
