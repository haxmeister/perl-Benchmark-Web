# Linux::Event::Net::HTTP benchmark target

Runner key: `linuxevent`

Adapter: `linuxevent-http.pl`

This target benchmarks Linux::Event::Net::HTTP using one event loop and one server process.

## Install

For an installed release:

```sh
cpanm Linux::Event::Net::HTTP
```

Verify that the required modules load:

```sh
perl -MLinux::Event::Loop \
     -MLinux::Event::Net::HTTP::Connection \
     -MLinux::Event::Net::HTTP::Server \
     -e 'print "ok\n"'
```

Benchmark::Web does not depend on Linux::Event::Net::HTTP. It is only needed when this target is selected.

## Development checkout

You can benchmark an uninstalled source checkout without installing it system-wide:

```sh
cd /path/to/perl-Linux-Event-Net-HTTP
perl Makefile.PL
make

cd /path/to/perl-Benchmark-Web/benchmarks/http
BENCH_LINUXEVENT_ROOT=/path/to/perl-Linux-Event-Net-HTTP \
  perl run.pl --servers=linuxevent --smoke --strict
```

`BENCH_LINUXEVENT_ROOT` must point at a built checkout containing `blib/lib` and `blib/arch`.

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=linuxevent --smoke --strict
```

## Adapter modes

`BENCH_LINUXEVENT_MODE` selects the response path:

```text
natural       ordinary on_request -> Response->end
request-end   response completed from on_request_end
fast-final    on_request_final default-final path
```

Example:

```sh
BENCH_LINUXEVENT_MODE=fast-final \
  perl run.pl --servers=linuxevent --smoke --strict
```

For requests with bodies, `natural` defers the response until `on_request_end` so the body is consumed before responding.

`BENCH_READ_BUDGET_BYTES` is passed through as the connection class `read_budget_bytes` stream option. It defaults to `0`.

Do not mix Linux::Event modes in one published result without labeling them separately.
\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n