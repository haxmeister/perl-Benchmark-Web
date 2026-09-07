from pathlib import Path
import re

root = Path('benchmarks/http')
run_path = root / 'run.pl'
text = run_path.read_text()

text = text.replace('use Cwd qw(abs_path);\n', '')

text, count = re.subn(
    r"\$SIG\{PIPE\} = 'IGNORE';\n\nmy \$go_binary = .*?my @servers = qw\(linuxevent hyperman feersum mojo node go aiohttp\);\n",
    """$SIG{PIPE} = 'IGNORE';

my %server = discover_servers();
my @prepared;
END { cleanup_servers(); }

my @servers = default_servers();
""",
    text,
    count=1,
    flags=re.S,
)
assert count == 1, 'failed to replace hard-coded server registry'

old_availability = r'''my (@available, @skipped);
for my $name (@servers) {
    if ($server{$name}{available}->()) {
        push @available, $name;
    } else {
        push @skipped, $name;
    }
}
if (@skipped && $strict) {
    die "unavailable benchmark servers: " . join(', ', @skipped) . "\n";
}
die "no requested benchmark servers are available\n" if !@available;

for my $name (@available) {
    $server{$name}{prepare}->() if $server{$name}{prepare};
}
'''
new_availability = r'''my (@available, @skipped);
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
if (@skipped && $strict) {
    die "unavailable benchmark servers: "
        . join(', ', map { "$_ ($skip_reason{$_})" } @skipped)
        . "\n";
}
die "no requested benchmark servers are available\n" if !@available;

my %server_version = map {
    $_ => launcher_capture($_, 'version')
} @available;
my %server_settings = map {
    $_ => (launcher_capture($_, 'settings') // '')
} @available;
'''
assert old_availability in text, 'availability block not found'
text = text.replace(old_availability, new_availability, 1)

old_env = r'''        environment => {
            perl => "$^V",
            linux_event_net_http => capture_linuxevent_version(),
            hyperman => capture($^X, '-MHyperman', '-e', 'print $Hyperman::VERSION'),
            feersum => capture($^X, '-MFeersum', '-e', 'print $Feersum::VERSION'),
            mojolicious => capture($^X, '-MMojolicious', '-e', 'print $Mojolicious::VERSION'),
            twiggy => capture($^X, '-MTwiggy', '-e', 'print $Twiggy::VERSION'),
            node => capture('node', '--version'),
            go => capture('go', 'version'),
            libh2o_evloop => capture('pkg-config', '--modversion', 'libh2o-evloop'),
            python => capture('python3', '--version'),
            aiohttp => capture('python3', '-c', 'import aiohttp; print(aiohttp.__version__)'),
            os => $sysname,
            kernel => $release,
            machine => $machine,
        },
'''
new_env = r'''        environment => {
            perl => "$^V",
            servers => {
                map {
                    $_ => {
                        label => $server{$_}{label},
                        version => $server_version{$_},
                        settings => $server_settings{$_},
                    }
                } @available
            },
            os => $sysname,
            kernel => $release,
            machine => $machine,
        },
'''
assert old_env in text, 'hard-coded environment block not found'
text = text.replace(old_env, new_env, 1)

text = text.replace(
    "            skipped => \\@skipped,\n",
    "            skipped => \\@skipped,\n            skipped_reasons => \\%skip_reason,\n",
    1,
)

old_skipped = "    my $skipped_labels = join(', ', map { $server{$_}{label} } @skipped);\n"
new_skipped = """    my $skipped_labels = join(', ', map {
        my $label = $server{$_}{label};
        my $reason = $skip_reason{$_};
        defined($reason) && length($reason) ? "$label [$reason]" : $label;
    } @skipped);
"""
assert old_skipped in text, 'skipped label line not found'
text = text.replace(old_skipped, new_skipped, 1)

old_linuxevent_summary = r'''    if (grep { $_ eq 'linuxevent' } @available) {
        printf "  %-25s %s\n", 'Linux::Event mode:',
            ($ENV{BENCH_LINUXEVENT_MODE} // 'natural');
    }
'''
new_generic_summary = r'''    for my $name (@available) {
        my $settings = $server_settings{$name};
        next if !defined($settings) || $settings eq '';
        printf "  %-25s %s: %s\n", 'Target setup:',
            $server{$name}{label}, $settings;
    }
'''
assert old_linuxevent_summary in text, 'Linux::Event-specific summary block not found'
text = text.replace(old_linuxevent_summary, new_generic_summary, 1)

text, count = re.subn(
    r"sub configure_linuxevent \(\) \{.*?\n\}\n\nsub capture_linuxevent_version \(\) \{.*?\n\}\n\n",
    '',
    text,
    count=1,
    flags=re.S,
)
assert count == 1, 'Linux::Event-specific runner helpers not found'

helpers = r'''sub discover_servers () {
    my $root = "$Bin/servers";
    opendir my $dh, $root or die "open benchmark server directory $root: $!\n";
    my %found;

    for my $key (sort readdir $dh) {
        next if $key =~ /\A\./;
        my $dir = "$root/$key";
        next if !-d $dir;
        my $launcher = "$dir/server.pl";
        next if !-f $launcher;
        die "invalid benchmark server key '$key'\n"
            if $key !~ /\A[a-z0-9][a-z0-9_-]*\z/;

        my $raw = capture($^X, $launcher, 'info');
        die "benchmark server $key: server.pl info failed\n"
            if !defined $raw;
        my $info = eval { JSON::PP->new->decode($raw) };
        die "benchmark server $key: server.pl info did not return a JSON object\n"
            if !$info || ref($info) ne 'HASH';
        die "benchmark server $key: info.label is required\n"
            if !defined($info->{label}) || ref($info->{label}) || $info->{label} eq '';

        my $order = defined($info->{order}) ? 0 + $info->{order} : 1000;
        $found{$key} = {
            label => "$info->{label}",
            default => $info->{default} ? 1 : 0,
            order => $order,
            launcher => $launcher,
        };
    }
    closedir $dh;

    die "no HTTP benchmark server adapters found under $root\n" if !%found;
    return %found;
}

sub default_servers () {
    my @default = grep { $server{$_}{default} } keys %server;
    die "no default HTTP benchmark servers are configured\n" if !@default;
    return sort {
        $server{$a}{order} <=> $server{$b}{order} || $a cmp $b
    } @default;
}

sub launcher_ok ($name, $action) {
    return command_ok($^X, $server{$name}{launcher}, $action);
}

sub launcher_capture ($name, $action) {
    return capture($^X, $server{$name}{launcher}, $action);
}

sub cleanup_servers () {
    for my $name (reverse @prepared) {
        command_ok($^X, $server{$name}{launcher}, 'cleanup');
    }
    return;
}

'''
marker = 'sub run_case ($name, $wire) {'
assert marker in text, 'run_case marker not found'
text = text.replace(marker, helpers + marker, 1)

old_exec = '        child_exec(@{$server{$name}{command}});\n'
new_exec = "        child_exec($^X, $server{$name}{launcher}, 'run');\n"
assert old_exec in text, 'hard-coded command exec not found'
text = text.replace(old_exec, new_exec, 1)

text, count = re.subn(
    r"sub usage \(\$status\) \{.*?\n\}\s*\Z",
    r'''sub usage ($status) {
    my @all = sort {
        $server{$a}{order} <=> $server{$b}{order} || $a cmp $b
    } keys %server;
    my @default = default_servers();
    my $all = join(',', @all);
    my $default = join(',', @default);

    print <<USAGE;
usage: run.pl [options]

  --servers=LIST           discovered server keys (available: $all)
                           default: $default
  --requests=N             measured requests per server/repeat (default 20000)
  --warmup=N               warmup requests per server/repeat (default 2000)
  --connections=N          concurrent TCP connections (default 100)
  --pipeline=N             max outstanding requests per connection (default 1)
  --request-body-bytes=N   fixed request body bytes (default 0)
  --response-bytes=N       fixed response body bytes (default 32)
  --repeats=N              rotated benchmark repeats (default 5)
  --timeout=SECONDS        server/client phase timeout (default 120)
  --strict                 fail instead of skipping unavailable competitors
  --no-strict              skip unavailable competitors (default)
  --json=PATH              write machine-readable report
  --smoke                  tiny keep-alive correctness workload
  --help                   show this help
USAGE
    exit $status;
}
''',
    text,
    count=1,
    flags=re.S,
)
assert count == 1, 'usage function not replaced'

run_path.write_text(text)

server_pl = {
'linuxevent': r'''#!/usr/bin/env perl
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
    exit perl_prefix() ? 0 : 1;
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
    push @candidate, $ENV{BENCH_LINUXEVENT_ROOT}
        if defined $ENV{BENCH_LINUXEVENT_ROOT};
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
''',
'hyperman': r'''#!/usr/bin/env perl
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
    exit $? == 0 ? 0 : 1;
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
''',
'feersum': r'''#!/usr/bin/env perl
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
''',
'mojo': r'''#!/usr/bin/env perl
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
''',
'node': r'''#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Node.js http', default => JSON::PP::true, order => 50 });
    exit 0;
}
if ($action eq 'probe') {
    system 'node', '--version';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') { exec 'node', '--version'; exit 127; }
if ($action eq 'settings') { print 'runtime=node:http, process=1'; exit 0; }
if ($action eq 'run') {
    exec 'node', "$Bin/node-http.js";
    die "exec node: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
''',
'go': r'''#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
my $binary = '/tmp/benchmark-web-http-go-' . getppid();
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Go net/http', default => JSON::PP::true, order => 60 });
    exit 0;
}
if ($action eq 'probe') {
    system 'go', 'version';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare') {
    system 'go', 'build', '-o', $binary, "$Bin/go-http.go";
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'cleanup') { unlink $binary if -e $binary; exit 0; }
if ($action eq 'version') { exec 'go', 'version'; exit 127; }
if ($action eq 'settings') { print 'GOMAXPROCS=1'; exit 0; }
if ($action eq 'run') {
    $ENV{GOMAXPROCS} = 1;
    exec $binary;
    die "exec $binary: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
''',
'aiohttp': r'''#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'Python aiohttp', default => JSON::PP::true, order => 70 });
    exit 0;
}
if ($action eq 'probe') {
    system 'python3', '-c', 'import aiohttp';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare' || $action eq 'cleanup') { exit 0; }
if ($action eq 'version') {
    exec 'python3', '-c', 'import aiohttp; print(aiohttp.__version__)';
    exit 127;
}
if ($action eq 'settings') { print 'aiohttp.web, access_log=off, process=1'; exit 0; }
if ($action eq 'run') {
    exec 'python3', "$Bin/aiohttp-http.py";
    die "exec python3: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
''',
'twiggy': r'''#!/usr/bin/env perl
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
''',
'h2o': r'''#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;
use FindBin qw($Bin);
use JSON::PP ();

my $action = shift // '';
my $binary = '/tmp/benchmark-web-http-h2o-' . getppid();
if ($action eq 'info') {
    print JSON::PP->new->canonical->encode({ label => 'libh2o evloop', default => JSON::PP::false, order => 90 });
    exit 0;
}
if ($action eq 'probe') {
    system 'cc', '--version';
    exit 1 if $? != 0;
    system 'pkg-config', '--exists', 'libh2o-evloop';
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'prepare') {
    my $flags = `pkg-config --cflags --libs libh2o-evloop 2>/dev/null`;
    exit 1 if $? != 0;
    my @flags = grep { length } split /\s+/, $flags;
    system 'cc', '-O2', '-o', $binary, "$Bin/libh2o-http.c", @flags;
    exit $? == 0 ? 0 : 1;
}
if ($action eq 'cleanup') { unlink $binary if -e $binary; exit 0; }
if ($action eq 'version') { exec 'pkg-config', '--modversion', 'libh2o-evloop'; exit 127; }
if ($action eq 'settings') { print 'library=libh2o-evloop, process=1, explicit-only'; exit 0; }
if ($action eq 'run') {
    exec $binary;
    die "exec $binary: $!\n";
}
die "usage: server.pl info|probe|prepare|version|settings|run|cleanup\n";
''',
}

for key, content in server_pl.items():
    path = root / 'servers' / key / 'server.pl'
    path.write_text(content)

# Keep the central README focused on the benchmark runner while documenting the
# generic launcher contract contributors implement in their own server folder.
readme = (root / 'README.md').read_text()
needle = '''Each target lives in its own directory. Its README owns installation instructions, setup details, adapter-specific settings, and a one-target smoke-test command.\n'''
replacement = needle + '''\n`run.pl` does not contain a registry of server implementations. It discovers subdirectories containing `server.pl`, reads their metadata, probes them, prepares them, and launches them through the same interface. Adding a conforming server directory does not require editing `run.pl`.\n'''
assert needle in readme, 'server runners paragraph not found'
readme = readme.replace(needle, replacement, 1)

adapter_heading = '## Adapter contract\n\nContributions from server authors are welcome.\n'
assert adapter_heading in readme, 'adapter contract heading not found'
launcher_contract = r'''## Server launcher contract

Every directory directly under `servers/` that participates in the matrix must contain a Perl launcher named `server.pl`. The directory name is the runner key. `run.pl` invokes every target through the same actions:

```text
perl servers/<key>/server.pl info
perl servers/<key>/server.pl probe
perl servers/<key>/server.pl prepare
perl servers/<key>/server.pl version
perl servers/<key>/server.pl settings
perl servers/<key>/server.pl run
perl servers/<key>/server.pl cleanup
```

The actions mean:

- `info` prints one JSON object with at least `label`; `default` selects whether the target joins the default matrix, and `order` controls stable display order.
- `probe` exits zero when the target can be used on this machine and nonzero otherwise.
- `prepare` performs target-specific setup such as compiling a temporary helper binary. It exits zero on success.
- `version` prints the target/runtime version used for the JSON report.
- `settings` prints a short human-readable summary of fairness-relevant target setup. It is included in the terminal summary and JSON report.
- `run` starts the server and does not return until the benchmark terminates it.
- `cleanup` removes temporary target-specific build artifacts and should succeed when there is nothing to remove.

`run.pl` supplies the benchmark workload inputs uniformly through `BENCH_PORT`, `BENCH_RESPONSE_BYTES`, and `BENCH_REQUEST_BODY_BYTES` when it invokes `run`. Those are part of the benchmark launcher contract. Any additional environment variables, runtime flags, build commands, source-checkout discovery, or other setup required by a particular implementation belongs inside that implementation's `server.pl`, not in `run.pl`.

A contributor may use any files they need inside their own server directory. Only `server.pl` and the benchmark protocol contract are visible to the central runner.

'''
readme = readme.replace(adapter_heading, launcher_contract + adapter_heading, 1)
(root / 'README.md').write_text(readme)

contrib = Path('CONTRIBUTING.md')
ctext = contrib.read_text()
needle = '''## Adding a competitor\n\nPrefer the smallest normal public API of the project being measured.\n'''
assert needle in ctext, 'contributing competitor section not found'
insert = r'''## Adding an HTTP server competitor

HTTP competitors are plug-ins at the filesystem level. Create:

```text
benchmarks/http/servers/<key>/
    README.md
    server.pl
    ... any adapter/source files needed by that target ...
```

Do not edit `benchmarks/http/run.pl` to register your server. The runner discovers `server.pl` automatically.

Your `server.pl` must implement the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions documented in `benchmarks/http/README.md`. Put target-specific dependency checks, build steps, environment setup, runtime flags, source-tree detection, and temporary-artifact cleanup there. The central runner should not learn framework-specific setup rules.

`README.md` in the same directory should explain how to install that target, verify it, run its one-target smoke test, and describe any tuning or fairness-relevant settings applied by the launcher or adapter.

Whether a target joins the default matrix is metadata returned by `server.pl info`; it is not a hard-coded list in `run.pl`.

'''
ctext = ctext.replace(needle, insert + needle, 1)
contrib.write_text(ctext)

for key in server_pl:
    path = root / 'servers' / key / 'README.md'
    rtext = path.read_text()
    anchor = f'Adapter: `'
    if '## Launcher interface' not in rtext:
        rtext += r'''\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n'''
    path.write_text(rtext)
