# Async and event-loop benchmarks

This directory is for benchmarks of asynchronous systems that are not HTTP server benchmarks.

Suitable subjects include:

- event-loop dispatch;
- callback scheduling;
- futures and awaitables;
- async read/write throughput;
- stream handling;
- timer and wakeup latency;
- concurrency scaling;
- backpressure and queue behavior;
- cancellation and completion overhead.

Each benchmark added here should live in its own subdirectory when it needs a distinct workload contract, adapters, fixtures, or documentation.

For example:

```text
benchmarks/async/
    callback-dispatch/
        README.md
        run.pl
    streams/
        README.md
        run.pl
    futures/
        README.md
        run.pl
```

Do not create one generic "async score" from unrelated operations. A callback-dispatch benchmark and a large-message stream benchmark answer different questions and should remain separately reproducible.

As with the rest of Benchmark::Web, benchmarked frameworks should remain optional dependencies. Runners should detect what is installed and clearly report skipped targets unless strict availability is requested.
