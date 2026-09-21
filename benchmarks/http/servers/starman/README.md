# Starman benchmark target

Runner key: `starman`

Adapter: `starman-http.psgi`

This target is explicit-only and is not part of the default comparison set.

## Install

Install Starman with your normal CPAN client:

```sh
cpanm Starman
```

Verify it:

```sh
perl -MStarman -e 'print "$Starman::VERSION\n"'
```

Benchmark::Web does not depend on Starman. It is only needed when this target is selected.

## Run

Starman is a blocking prefork server. The benchmark fixes it at one worker so there is only one application execution slot. One worker can service only one persistent connection at a time, so this adapter declares `max_persistent_connections => 1`.

From `benchmarks/http/`:

```sh
perl run.pl \
  --servers=starman \
  --requests=20000 \
  --warmup=2000 \
  --connections=1 \
  --repeats=5 \
  --strict
```

If a run requests more than one persistent connection, the shared runner skips Starman in non-strict mode or rejects the matrix in strict mode before starting it. This avoids silently changing Starman to multiple workers, which would violate the benchmark's single-application-execution-slot profile.

## Adapter setup

The launcher uses the normal `starman` command with one worker, keep-alive enabled, application preloading, and a very high worker request limit so recycling does not perturb a measured run.

Starman still has its normal idle prefork master process in addition to the active worker, so it is kept explicit-only and that process-model difference is visible in the target settings.

The PSGI application consumes any request body and returns the same fixed `Content-Length` response shape as the other HTTP adapters.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` contains no Starman-specific branch.
