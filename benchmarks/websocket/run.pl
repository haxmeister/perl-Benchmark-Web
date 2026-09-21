#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(make_path);
use FindBin qw($Bin);
use Getopt::Long qw(GetOptions);
use IO::Select;\nuse IO::Socket::INET;
use JSON::PP ();
use POSIX qw(WNOHANG strftime uname);
use Time::HiRes qw(sleep time);

die "shared WebSocket client dependency is unavailable; run 'npm install' in benchmarks/websocket\n"
    if system('node', "$Bin/probe-client.mjs") != 0;

my %server = discover_servers();
my @prepared;
END {
    my $status = $?;
    cleanup_servers();
    $? = $status;
}

my @servers = default_servers();
my $bytes = 256;
my $connections = 100;
my $window = 4;
my $warmup = 0.75;
my $seconds = 3;
my $repeats = 5;
my $timeout = 120;
my $strict = 0;
my $smoke = 0;
my $json_path;
my $help = 0;

GetOptions(
    'servers=s'     => sub { @servers = split /,/, $_[1] },
    'bytes=i'       => \$bytes,
    'connections=i' => \$connections,
    'window=i'      => \$window,
    'warmup=f'      => \$warmup,
    'seconds=f'     => \$seconds,
    'repeats=i'     => \$repeats,
    'timeout=f'     => \$timeout,
    'strict!'       => \$strict,
    'smoke'         => \$smoke,
    'json=s'        => \$json_path,
    'help'          => \$help,
) or usage(2);

usage(0) if $help;
if ($smoke) {
    $bytes = 64;
    $connections = 4;
    $window = 1;
    $warmup = 0.2;
    $seconds = 0.5;
    $repeats = 1;
    $timeout = 20;
}

die "bytes must be >= 55\n" if $bytes < 55;
die "connections must be > 0\n" if $connections <= 0;
die "window must be > 0\n" if $window <= 0;
die "warmup must be >= 0\n" if $warmup < 0;
die "seconds must be > 0\n" if $seconds <= 0;
die "repeats must be > 0\n" if $repeats <= 0;
die "timeout must be > 0\n" if $timeout <= 0;
die "at least one server is required\n" if !@servers;
die "unknown server: $_\n" for grep { !exists $server{$_} } @servers;

my (@available, @skipped);
my %skip_reason;
for my $name (@servers) {
    if (!launcher_ok($name, 'probe')) {
        push @skipped, $name;
        $skip_reason{$name} = 'probe failed';
        next;
    }
    if (!launcher_ok($name, 'prepare')) {
        push @skipped, $name;
        $skip_reason{$name} = 'prepare failed';
        next;
    }
    push @prepared, $name;
    push @available, $name;
}
die "unavailable benchmark servers: " . join(', ', @skipped) . "\n"
    if @skipped && $strict;
die "no requested benchmark servers are available\n" if !@available;

my %version = map { $_ => launcher_capture($_, 'version') } @available;
my %settings = map { $_ => launcher_capture($_, 'settings') // '' } @available;
my @records;

say 'Benchmark::Web WebSocket application comparison';
say 'servers=' . join(',', @available);
say 'skipped=' . join(',', @skipped) if @skipped;
say "bytes=$bytes connections=$connections window=$window warmup=$warmup seconds=$seconds repeats=$repeats";
say 'mode=single-process single-execution-slot loopback-tcp shared-client application-request-ack';

for my $repeat (1 .. $repeats) {
    for my $name (rotated_servers($repeat, @available)) {
        my $row = run_case($name);
        $row->{repeat} = $repeat;
        push @records, $row;
        printf "%-28s repeat=%d %10.1f txn/s\n",
            $server{$name}{label}, $repeat, $row->{transactions_per_second};
    }
}

my @summary;
for my $name (@available) {
    my @set = grep { $_->{server} eq $name } @records;
    push @summary, {
        server => $name,
        label => $server{$name}{label},
        transactions_per_second => median(map { $_->{transactions_per_second} } @set),
    };
}

say '';
say 'Median summary';
for my $row (@summary) {
    printf "%-28s %10.1f txn/s  %s\n",
        $row->{label}, $row->{transactions_per_second}, $settings{$row->{server}};
}

if (defined $json_path) {
    my ($sysname, $nodename, $release, $os_version, $machine) = uname();
    my $report = {
        benchmark => 'benchmark-web-websocket-application',
        benchmark_contract_version => 1,
        generated_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        environment => {
            perl => "$^V",
            os => $sysname,
            kernel => $release,
            machine => $machine,
            servers => {
                map {
                    $_ => {
                        label => $server{$_}{label},
                        version => $version{$_},
                        settings => $settings{$_},
                    }
                } @available
            },
        },
        configuration => {
            servers => \@available,
            skipped => \@skipped,
            skipped_reasons => \%skip_reason,
            bytes => $bytes,
            connections => $connections,
            window => $window,
            warmup_seconds => $warmup,
            measure_seconds => $seconds,
            repeats => $repeats,
            timeout => $timeout,
        },
        summary => \@summary,
        records => \@records,
    };
    my $dir = dirname($json_path);
    make_path($dir) if $dir ne '.' && !-d $dir;
    open my $fh, '>', $json_path or die "open $json_path: $!\n";
    print {$fh} JSON::PP->new->canonical->pretty->encode($report);
    close $fh or die "close $json_path: $!\n";
    say "json=$json_path";
}

sub run_case ($name) {
    my $port = free_port();
    local $ENV{BENCH_PORT} = $port;
    my $pid = fork();
    die "fork server: $!\n" if !defined $pid;
    if ($pid == 0) {
        exec $server{$name}{launcher}, 'run';
        POSIX::_exit(127);
    }

    my ($row, $error);
    eval {
        wait_for_port($pid, $port);
        my @command = (
            'node', "$Bin/load.mjs",
            '--label', $name,
            '--port', $port,
            '--bytes', $bytes,
            '--connections', $connections,
            '--window', $window,
            '--warmup', $warmup,
            '--seconds', $seconds,
        );
        my $line = capture_timeout($timeout, @command)
            // die "client failed for $name\n";
        my ($label, $got_bytes, $got_connections, $got_window, $messages, $elapsed, $rate)
            = split /,/, $line;
        die "malformed client result for $name: $line\n"
            if !defined($rate) || $label ne $name;
        $row = {
            server => $name,
            bytes => 0 + $got_bytes,
            connections => 0 + $got_connections,
            window => 0 + $got_window,
            messages => 0 + $messages,
            seconds => 0 + $elapsed,
            transactions_per_second => 0 + $rate,
        };
        1;
    } or $error = $@ || "benchmark case failed\n";

    kill 'TERM', $pid;
    waitpid($pid, 0);
    die $error if defined $error;
    return $row;
}

sub wait_for_port ($pid, $port) {
    my $deadline = time + $timeout;
    while (time < $deadline) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp',
            Timeout => 0.05,
        );
        if ($sock) { close $sock; return }
        my $done = waitpid($pid, WNOHANG);
        die "server exited before listening\n" if $done == $pid;
        sleep 0.03;
    }
    die "server startup timed out\n";
}

sub free_port () {
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 1,
        ReuseAddr => 1,
    ) or die "allocate port: $!\n";
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

sub discover_servers () {
    my %found;
    for my $launcher (glob "$Bin/servers/*/server.pl") {
        (my $key = $launcher) =~ s{.*/servers/([^/]+)/server\.pl\z}{$1};
        my $json = capture($^X, $launcher, 'info') // next;
        my $info = eval { JSON::PP->new->decode($json) } // next;
        $found{$key} = {
            launcher => $launcher,
            label => $info->{label} // $key,
            default => $info->{default} ? 1 : 0,
            order => $info->{order} // 1000,
        };
    }
    return %found;
}

sub default_servers () {
    return sort {
        $server{$a}{order} <=> $server{$b}{order} || $a cmp $b
    } grep { $server{$_}{default} } keys %server;
}

sub launcher_ok ($name, $action) {
    return system($^X, $server{$name}{launcher}, $action) == 0;
}

sub launcher_capture ($name, $action) {
    return capture($^X, $server{$name}{launcher}, $action);
}

sub cleanup_servers () {
    for my $name (reverse @prepared) {
        system $^X, $server{$name}{launcher}, 'cleanup';
    }
}

sub capture_timeout ($limit, @command) {
    pipe(my $read, my $write) or die "pipe: $!\n";
    my $pid = fork();
    die "fork: $!\n" if !defined $pid;
    if ($pid == 0) {
        close $read;
        open STDOUT, '>&', $write or POSIX::_exit(126);
        close $write;
        exec @command;
        POSIX::_exit(127);
    }
    close $write;

    my $select = IO::Select->new($read);
    my $deadline = time + $limit;
    my $text = '';
    my $exited = 0;

    while (time < $deadline) {
        if ($select->can_read(0.05)) {
            my $chunk = '';
            my $n = sysread($read, $chunk, 65536);
            if (defined($n) && $n > 0) {
                $text .= $chunk;
            } elsif (defined($n) && $n == 0) {
                $select->remove($read);
            }
        }

        my $done = waitpid($pid, WNOHANG);
        if ($done == $pid) {
            $exited = 1;
            last;
        }
    }

    if (!$exited) {
        kill 'TERM', $pid;
        waitpid($pid, 0);
        close $read;
        return undef;
    }

    while ($select->count && $select->can_read(0)) {
        my $chunk = '';
        my $n = sysread($read, $chunk, 65536);
        last if !defined($n) || $n == 0;
        $text .= $chunk;
    }
    close $read;
    return undef if $? != 0;
    $text =~ s/\A\s+|\s+\z//g;
    return $text;
}

sub capture (@command) {
    pipe(my $read, my $write) or return undef;
    my $pid = fork();
    return undef if !defined $pid;
    if ($pid == 0) {
        close $read;
        open STDOUT, '>&', $write or POSIX::_exit(126);
        open STDERR, '>', '/dev/null';
        close $write;
        exec @command;
        POSIX::_exit(127);
    }
    close $write;
    local $/;
    my $text = <$read> // '';
    close $read;
    waitpid($pid, 0);
    return undef if $? != 0;
    $text =~ s/\A\s+|\s+\z//g;
    return $text;
}

sub median (@values) {
    return 0 if !@values;
    @values = sort { $a <=> $b } @values;
    my $mid = int(@values / 2);
    return @values % 2 ? $values[$mid] : ($values[$mid - 1] + $values[$mid]) / 2;
}

sub rotated_servers ($repeat, @list) {
    return @list if @list < 2;
    my $offset = ($repeat - 1) % @list;
    return (@list[$offset .. $#list], @list[0 .. $offset - 1]);
}

sub usage ($status) {
    my @all = sort {
        $server{$a}{order} <=> $server{$b}{order} || $a cmp $b
    } keys %server;
    print <<"USAGE";
usage: run.pl [options]

  --servers=LIST      discovered server keys (available: @{[join ',', @all]})
  --bytes=N           text request bytes (default 256)
  --connections=N     concurrent WebSocket connections (default 100)
  --window=N          outstanding requests per connection (default 4)
  --warmup=SECONDS    unmeasured warmup (default 0.75)
  --seconds=SECONDS   measured duration (default 3)
  --repeats=N         rotated repeats (default 5)
  --timeout=SECONDS   startup/client timeout (default 120)
  --strict            fail instead of skipping unavailable targets
  --json=PATH         write machine-readable report
  --smoke             tiny correctness workload
  --help              show this help
USAGE
    exit $status;
}
