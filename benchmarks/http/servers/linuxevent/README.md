# Linux::Event::HTTP benchmark target

Runner key: `linuxevent`

Adapter: `linuxevent-http.pl`

This target benchmarks the current `Linux::Event::HTTP` distribution using one
Linux::Event loop and one server process.

## Recommended install

Benchmark::Web keeps Linux::Event and Linux::Event::HTTP target-local; neither is
a dependency of Benchmark::Web itself.

On Debian/Ubuntu/Devuan, install the ordinary build tools and `cpanm`:

```sh
sudo apt update
sudo apt install build-essential git cpanminus
```

Then, from this directory:

```sh
bash install.sh
```

The installer:

1. clones current `haxmeister/perl-linux-event` into
   `servers/linuxevent/.source/core/`;
2. installs that Linux::Event into `servers/linuxevent/.local/`;
3. verifies Linux::Event 0.116 or newer;
4. clones current `haxmeister/perl-Linux-Event-HTTP` into
   `servers/linuxevent/.source/http/`;
5. installs the HTTP distribution's prerequisites into the same target-local
   library;
6. builds Linux::Event::HTTP against that target-local Linux::Event;
7. prints both source commit IDs and verifies that `server.pl` can load the
   resulting runtime.

The `cpanm` script is executed through the same `perl` found in the current
shell. This matters on perlbrew and similar installations because XS modules
must be built for the Perl that runs the benchmark.

No `PERL5LIB` or global installation is required. `server.pl` adds the
target-local library and HTTP `blib` directories itself.

The generated `.local/` and `.source/` trees are ignored by Git.

After installation:

```sh
perl server.pl probe
perl server.pl version
perl server.pl settings
```

Then run from `benchmarks/http/`:

```sh
perl run.pl --servers=linuxevent --smoke --strict
```

To build particular branch or tag names instead of `main`, pass the HTTP ref
first and Linux::Event ref second:

```sh
bash install.sh HTTP_REF CORE_REF
```

## Development checkout

`server.pl` can benchmark an already-built Linux::Event::HTTP checkout.

If `perl-Benchmark-Web` and `perl-Linux-Event-HTTP` are sibling directories,
the launcher detects the HTTP checkout automatically:

```text
work/
    perl-Benchmark-Web/
    perl-Linux-Event-HTTP/
```

Build that checkout normally against an available Linux::Event:

```sh
cd /path/to/work/perl-Linux-Event-HTTP
perl Makefile.PL
make
```

If the checkout is elsewhere, put its path in the target-local `source-root`
file:

```sh
printf '%s\n' /path/to/perl-Linux-Event-HTTP \
  > servers/linuxevent/source-root
```

## Adapter modes

The public comparison target uses `natural` mode and
`read_budget_bytes=0`. It exercises the normal public
`Linux::Event::HTTP::Server` /
`Linux::Event::HTTP::Server::Connection` API.

For requests without bodies, `natural` replies from `on_request`. For
request-body workloads, it waits for `on_request_end` so the complete request
body is consumed before responding, matching Benchmark::Web's cross-server
workload contract.

The response uses `Content-Type: application/octet-stream` and a complete scalar
`Response->body`.

For development-only measurements, `BENCH_LINUXEVENT_MODE=raw-native` selects
the distribution's currently internal raw native HTTP/1 consumer path:

```sh
BENCH_LINUXEVENT_MODE=raw-native \
  perl run.pl --servers=linuxevent --requests=50000 --repeats=5
```

That mode is deliberately not the default Benchmark::Web result while raw native
input remains an internal/opt-in Linux::Event::HTTP capability.

`BENCH_READ_BUDGET_BYTES` overrides the connection class
`read_budget_bytes` stream tuning value. The launcher reports the selected
source, mode, and read budget through its `settings` action.

Do not mix Linux::Event modes in one published result without labeling them.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner
discovers it automatically and uses the standard `info`, `probe`, `prepare`,
`version`, `settings`, `run`, and `cleanup` actions. Target-specific setup
belongs here; `run.pl` contains no Linux::Event special case.
