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

`server.pl` can benchmark a built checkout without installing it system-wide.

If `perl-Benchmark-Web` and `perl-Linux-Event-Net-HTTP` are sibling directories, the launcher finds the HTTP checkout automatically:

```text
work/
    perl-Benchmark-Web/
    perl-Linux-Event-Net-HTTP/
```

Build the HTTP checkout normally:

```sh
cd /path/to/work/perl-Linux-Event-Net-HTTP
perl Makefile.PL
make
```

Then run the benchmark from `perl-Benchmark-Web/benchmarks/http/` with no environment-variable setup:

```sh
perl run.pl --servers=linuxevent --smoke --strict
```

If the checkout is elsewhere, put its path in the target-local `source-root` file:

```sh
printf '%s\n' /path/to/perl-Linux-Event-Net-HTTP \
  > servers/linuxevent/source-root
```

The launcher reads that file and adds the checkout's `blib/lib` and `blib/arch` itself.

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=linuxevent --smoke --strict
```

## Adapter modes

The normal matrix uses `natural` mode and `read_budget_bytes=0`; `server.pl` applies those defaults itself.

For development comparisons, `BENCH_LINUXEVENT_MODE` can override the response path:

```text
natural       ordinary on_request -> Response->end
request-end   response completed from on_request_end
fast-final    on_request_final default-final path
```

`BENCH_READ_BUDGET_BYTES` can likewise override the connection class `read_budget_bytes` stream option. These are optional benchmark-development overrides, not installation/setup requirements. The selected values are reported by the generic `settings` action and therefore appear in the terminal summary and JSON output.

For requests with bodies, `natural` defers the response until `on_request_end` so the body is consumed before responding.

Do not mix Linux::Event modes in one published result without labeling them separately.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.
