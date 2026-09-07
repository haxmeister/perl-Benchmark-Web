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
