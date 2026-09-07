#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

configure_pkg_config_path();

my $action = shift // '';
my $binary = '/tmp/benchmark-web-http-h2o-' . getppid();

if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'libh2o evloop',
        default => JSON::PP::false,
        order => 90,
    });
    exit 0;
}
if ($action eq 'probe') {
    system 'cc', '--version';
    exit 1 if $? != 0;
    system 'pkg-config', '--exists', 'libh2o-evloop';
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'prepare') {
    my $flags = `pkg-config --cflags --libs libh2o-evloop 2>/dev/null`;
    exit 1 if $? != 0;
    my @flags = grep { length } split /\s+/, $flags;
    system 'cc', '-O2', '-o', $binary, "$Bin/libh2o-http.c", @flags;
    exit(($? == 0) ? 0 : 1);
}
if ($action eq 'cleanup') {
    unlink $binary if -e $binary;
    exit 0;
}
if ($action eq 'version') {
    exec 'pkg-config', '--modversion', 'libh2o-evloop';
    exit 127;
}
if ($action eq 'settings') {
    print 'library=libh2o-evloop, process=1, explicit-only';
    exit 0;
}
if ($action eq 'run') {
    exec $binary;
    die "exec $binary: $!\n";
}

die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";

sub configure_pkg_config_path () {
    my @candidate = (
        '/usr/local/lib/pkgconfig',
        '/usr/local/lib64/pkgconfig',
        '/usr/local/share/pkgconfig',
        glob('/usr/local/lib/*/pkgconfig'),
    );
    my %seen;
    my @path = grep { -d $_ && !$seen{$_}++ } @candidate;
    if (defined($ENV{PKG_CONFIG_PATH}) && length($ENV{PKG_CONFIG_PATH})) {
        push @path, grep { length && !$seen{$_}++ }
            split /:/, $ENV{PKG_CONFIG_PATH};
    }
    $ENV{PKG_CONFIG_PATH} = join(':', @path) if @path;
    return;
}
