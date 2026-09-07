#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';

if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({
        label => 'Linux::Event::Net::HTTP',
        default => JSON::PP::true,
        order => 10,
    });
    exit 0;
}
if ($action eq 'probe') {
    exit(perl_prefix() ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') {
    exit 0;
}
if ($action eq 'version') {
    my $prefix = perl_prefix() or exit 1;
    exec @$prefix,
        '-MLinux::Event::Net::HTTP',
        '-e', 'print $Linux::Event::Net::HTTP::VERSION';
    exit 127;
}
if ($action eq 'settings') {
    my $mode = $ENV{BENCH_LINUXEVENT_MODE} // 'natural';
    my $budget = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
    print "mode=$mode, read_budget_bytes=$budget";
    exit 0;
}
if ($action eq 'run') {
    my $prefix = perl_prefix() or die "Linux::Event::Net::HTTP is unavailable\n";
    $ENV{BENCH_LINUXEVENT_MODE} //= 'natural';
    $ENV{BENCH_READ_BUDGET_BYTES} //= 0;
    exec @$prefix, "$Bin/linuxevent-http.pl";
    die "exec linuxevent-http.pl: $!\n";
}

die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";

sub perl_prefix () {
    for my $root (checkout_candidates()) {
        next if !defined($root) || $root eq '';
        my $abs = abs_path($root) // next;
        my $lib = "$abs/blib/lib";
        my $arch = "$abs/blib/arch";
        next if !-f "$lib/Linux/Event/Net/HTTP.pm" || !-d $arch;
        my @prefix = ($^X, "-I$lib", "-I$arch");
        return \@prefix if modules_ok(@prefix);
    }

    my @installed = ($^X);
    return \@installed if modules_ok(@installed);
    return undef;
}

sub checkout_candidates () {
    my @candidate;

    my $source_root = "$Bin/source-root";
    if (-f $source_root) {
        open my $fh, '<', $source_root or die "open $source_root: $!\n";
        my $root = <$fh> // '';
        close $fh;
        chomp $root;
        push @candidate, $root if length $root;
    }

    my $repo = abs_path("$Bin/../../../..");
    push @candidate, "$repo/../perl-Linux-Event-Net-HTTP" if defined $repo;

    return @candidate;
}

sub modules_ok (@prefix) {
    system @prefix,
        '-MLinux::Event::Loop',
        '-MLinux::Event::Net::HTTP::Connection',
        '-MLinux::Event::Net::HTTP::Server',
        '-e', '1';
    return $? == 0;
}
