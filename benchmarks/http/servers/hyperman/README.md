# Hyperman benchmark target

Runner key: `hyperman`

Adapter: `hyperman-http.pl`

## Install

Install Hyperman with your normal CPAN client:

```sh
cpanm Hyperman
```

Verify it:

```sh
perl -MHyperman -e 'print "$Hyperman::VERSION\n"'
```

Benchmark::Web does not depend on Hyperman. It is only needed when this target is selected.

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=hyperman --smoke --strict
```

A normal measurement example:

```sh
perl run.pl \
  --servers=hyperman \
  --requests=50000 \
  --warmup=5000 \
  --connections=100 \
  --repeats=5
```

## Adapter setup

The adapter uses Hyperman's PSGI-style application API. It configures `workers => 1` so the benchmark stays in one process/application execution slot and explicitly disables compression. For very large benchmark request bodies it raises Hyperman's body limit enough to accept the configured workload.
\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n