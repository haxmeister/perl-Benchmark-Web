# Benchmark::Web

Benchmark::Web is a neutral collection of reproducible benchmarks for Perl web,
networking, event-loop, and asynchronous systems, with selected non-Perl
implementations included where they provide useful reference points.

It is **not** tied to one HTTP server, event loop, or async framework.

The repository is organized by benchmark family so each comparison has its own
workload contract, adapters, documentation, and result interpretation.

## Benchmark families

### HTTP server comparison

[`benchmarks/http/`](benchmarks/http/)

Cross-server HTTP/1.1 throughput and client-visible latency using one shared raw
client and the same request/response workload for every server.

Current adapters include Linux::Event::Net::HTTP, Hyperman, Feersum,
Mojolicious, Node.js, Go, aiohttp, and optional reference servers.

**Linux::Event is not required. Hyperman is not required. No benchmarked server
is a project dependency.**

### Async and event-loop comparisons

[`benchmarks/async/`](benchmarks/async/)

This family is intended for comparisons that are not HTTP benchmarks: event
loops, callback dispatch, futures/awaitables, async I/O, stream workloads,
latency under concurrency, and related primitives.

The exact workloads should be documented individually rather than forcing unlike
async systems into one vague score.

## Repository layout

```text
benchmarks/
    http/
        README.md
        run.pl
        servers/
    async/
        README.md
```

Additional benchmark families can be added when they have a distinct workload
contract. Examples might include streams, WebSocket, timers, scheduling, or
socket lifecycle benchmarks.

## Principles

### Competitors are optional

A benchmark target must not become a required dependency merely because we want
to measure it. Runners should detect available implementations and either skip
missing ones or fail only when the user explicitly requests strict availability.

### One benchmark, one stated question

A benchmark should say exactly what it measures. HTTP request throughput,
callback dispatch, future completion, stream framing, and worker scaling are
different questions and should not be collapsed into one number.

### Shared workload before shared conclusions

Where systems are compared directly, they should receive the same workload from
the same client/driver whenever practical. Differences that cannot be normalized
should be documented rather than hidden.

### Reproducibility over impressive numbers

Benchmark settings, runtime/framework versions, OS/kernel information, and raw
machine-readable results should be retainable. Multiple repeats and medians are
preferred over best-of runs.

### Public benchmarks should explain themselves

Every benchmark family should have its own README containing:

- what question the benchmark answers;
- the workload contract;
- every command-line setting;
- installation/runtime requirements;
- fairness constraints;
- copy-paste examples;
- guidance for interpreting and publishing results.

## Contributing

Contributions are welcome, especially adapters from the authors or maintainers of
the systems being measured.

When adding a benchmark target, use that project's normal public API and avoid
artificially handicapping or specially optimizing one competitor. If a project
has a recommended benchmark configuration that still fits the benchmark's
contract, document why it is used.

Keep dependencies optional. A contributor should be able to work on one
benchmark family without installing every framework represented elsewhere in the
repository.

See the README inside each benchmark family for its specific adapter contract.
