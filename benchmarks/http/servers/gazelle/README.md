# Gazelle benchmark target

Runner key: `gazelle`

Adapter: `gazelle-http.psgi`

This target is explicit-only and is not part of the default comparison set.

## Install

Install Gazelle with your normal CPAN client:

```sh
cpanm Gazelle
```

Verify it:

```sh
perl -MGazelle -e 'print "$Gazelle::VERSION\n"'
```

Benchmark::Web does not depend on Gazelle.

## Current benchmark status

Gazelle 0.50 documents HTTP/1.1 support without keep-alive support. The Benchmark::Web HTTP comparison intentionally keeps each client connection open across many requests, so running Gazelle in the current workload would change the connection lifecycle and would not be an apples-to-apples result.

The target therefore declares the current workload unsupported in `server.pl info`. A mixed non-strict matrix skips Gazelle before dependency probing or startup and records the reason in terminal and JSON output.

For example:

```sh
perl run.pl --servers=node,gazelle --smoke
```

A strict matrix that includes Gazelle is rejected immediately.

The adapter and launcher are kept here so Gazelle is represented accurately and can be used by a future connection-churn/non-keepalive HTTP workload without reintroducing target-specific setup into the central runner.

## Adapter setup

The launcher is prepared to use the normal `plackup -s Gazelle` interface with one worker and a high request-recycling limit. The PSGI application consumes request bodies and returns the benchmark's fixed response shape.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` contains no Gazelle-specific branch.
