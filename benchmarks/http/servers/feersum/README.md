# Feersum benchmark target

Runner key: `feersum`

Adapter: `feersum-http.pl`

## Install

Install Feersum with your normal CPAN client:

```sh
cpanm Feersum
```

Verify the runner module:

```sh
perl -MFeersum::Runner -e 'print "ok\n"'
```

Benchmark::Web does not depend on Feersum. It is only needed when this target is selected.

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=feersum --smoke --strict
```

## Adapter setup

The adapter uses `Feersum::Runner` with prefork disabled, keep-alive enabled, unlimited requests per connection, and quiet mode enabled. Request bodies are consumed before the fixed benchmark response is sent.
\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n