# Mojolicious benchmark target

Runner key: `mojo`

Adapter: `mojo-http.pl`

## Install

Install Mojolicious with your normal CPAN client:

```sh
cpanm Mojolicious
```

Verify it:

```sh
perl -MMojolicious -e 'print "$Mojolicious::VERSION\n"'
```

Benchmark::Web does not depend on Mojolicious. It is only needed when this target is selected.

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=mojo --smoke --strict
```

## Adapter setup

The adapter uses a `Mojolicious` application with `Mojo::Server::Daemon`, one process, silent server output, a high request limit, and keep-alive enabled for the benchmark workload. The `/bench` route consumes the request body and returns the fixed response payload.
\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n