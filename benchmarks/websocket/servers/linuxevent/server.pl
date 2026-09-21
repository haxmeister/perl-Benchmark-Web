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
        label => 'Linux::Event::WebSocket',
        default => JSON::PP::true,
        order => 10,
    });
    exit 0;
}
if ($action eq 'probe') {
    exit(resolve_runtime() ? 0 : 1);
}
if ($action eq 'prepare' || $action eq 'cleanup') {
    exit 0;
}
if ($action eq 'version') {
    my $runtime = resolve_runtime() or exit 1;
    exec @{$runtime->{prefix}},
        '-MLinux::Event::WebSocket',
        '-e', 'print $Linux::Event::WebSocket::VERSION';
    exit 127;
}
if ($action eq 'settings') {
    my $runtime = resolve_runtime();
    print 'source=' . ($runtime ? $runtime->{source} : 'unavailable')
        . ', process=1';
    exit 0;
}
if ($action eq 'run') {
    my $runtime = resolve_runtime()
        or die "Linux::Event::WebSocket is unavailable\n";
    exec @{$runtime->{prefix}}, "$Bin/linuxevent-websocket.pl";
    die "exec linuxevent-websocket.pl: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";

sub resolve_runtime () {
    for my $candidate (checkout_candidates()) {
        my ($root, $source) = @$candidate;
        next if !defined($root) || $root eq '';
        my $abs = abs_path($root) // next;
        my $lib = "$abs/blib/lib";
        my $arch = "$abs/blib/arch";
        next if !-f "$lib/Linux/Event/WebSocket.pm" || !-d $arch;
        my @prefix = ($^X, "-I$lib", "-I$arch");
        return { prefix => \@prefix, source => $source }
            if modules_ok(@prefix);
    }

    my @installed = ($^X);
    return { prefix => \@installed, source => 'installed' }
        if modules_ok(@installed);
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
        push @candidate, [$root, 'source-root'] if length $root;
    }

    my $repo = abs_path("$Bin/../../../..");
    push @candidate,
        ["$repo/../perl-Linux-Event-WebSocket", 'sibling-checkout']
        if defined $repo;
    return @candidate;
}

sub modules_ok (@prefix) {
    system @prefix,
        '-MLinux::Event::Loop',
        '-MLinux::Event::WebSocket::Server',
        '-e', '1';
    return $? == 0;
}
