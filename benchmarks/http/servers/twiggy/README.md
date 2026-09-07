# Twiggy benchmark target

Runner key: `twiggy`

Adapter: `twiggy-http.pl`

This target is explicit-only and is not part of the default comparison set.

## Install

Install Twiggy with your normal CPAN client:

```sh
cpanm Twiggy
```

Twiggy will install its normal AnyEvent dependencies.

Verify it:

```sh
perl -MTwiggy -e 'print "$Twiggy::VERSION\n"'
```

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=twiggy --smoke --strict
```

## Current benchmark status

Stock Twiggy is incompatible with this benchmark's persistent HTTP/1.1 connection contract: it closes the connection after each response. The target therefore declares this workload unsupported in `server.pl info`.

A non-strict mixed matrix skips Twiggy before starting it and records the reason in the terminal summary and JSON report. Selecting Twiggy with `--strict`, or selecting only Twiggy, fails immediately with that reason instead of failing midway with `server closed connection before benchmark phase completed`.

The adapter remains in the repository for documentation and for a future benchmark family whose connection lifecycle matches Twiggy.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.
