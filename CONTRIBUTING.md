# Contributing to Benchmark::Web

Contributions are welcome from users and especially from authors or maintainers of systems represented in the benchmarks.

The goal is not to produce one universal ranking. The goal is to make narrowly defined comparisons reproducible and inspectable.

## Adding a benchmark family

Create a directory under `benchmarks/` when the workload answers a meaningfully different question.

Examples:

```text
benchmarks/http/
benchmarks/async/callback-dispatch/
benchmarks/async/streams/
benchmarks/websocket/
```

Every benchmark family should document:

- what it measures;
- what it deliberately does not measure;
- its workload contract;
- all user-facing settings;
- fairness constraints;
- required and optional runtimes;
- how results should be interpreted;
- how to retain machine-readable results where supported.

## Adding an HTTP server competitor

HTTP competitors are plug-ins at the filesystem level. Create:

```text
benchmarks/http/servers/<key>/
    README.md
    server.pl
    ... any adapter/source files needed by that target ...
```

Do not edit `benchmarks/http/run.pl` to register your server. The runner discovers `server.pl` automatically.

Your `server.pl` must implement the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions documented in `benchmarks/http/README.md`. Put target-specific dependency checks, build steps, environment setup, runtime flags, source-tree detection, and temporary-artifact cleanup there. The central runner should not learn framework-specific setup rules.

`README.md` in the same directory should explain how to install that target, verify it, run its one-target smoke test, and describe any tuning or fairness-relevant settings applied by the launcher or adapter.

Whether a target joins the default matrix is metadata returned by `server.pl info`; it is not a hard-coded list in `run.pl`.

## Adding a competitor

Prefer the smallest normal public API of the project being measured.

Do not intentionally handicap a competitor. Do not add project-specific tuning merely to improve a number unless that tuning is the project's normal documented recommendation and still satisfies the benchmark contract. Document any such choice.

If you maintain one of the compared projects and believe its adapter is unfair or unrepresentative, please open an issue or pull request with the concrete configuration/API you recommend.

## Dependencies

Benchmarked systems must remain optional.

Do not make Hyperman, Linux::Event, Feersum, Mojolicious, Twiggy, aiohttp, or another benchmark target a required dependency just so its benchmark can run.

A runner should detect missing competitors and skip them by default, with a strict mode when a reproducible run requires an exact target set.

CI may install optional benchmark targets temporarily to exercise adapters. That does not make those targets project dependencies: do not add them to core package metadata or assume every contributor has them installed.

## Results

Do not present smoke tests or one-off shared-CI measurements as authoritative performance results.

Prefer multiple repeats, medians, recorded settings, runtime/framework versions, and a stable machine. Keep machine-readable output when the benchmark provides it.

When publishing comparisons, include enough information for another person to rerun the same workload.
