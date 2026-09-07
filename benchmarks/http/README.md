# HTTP server comparison

This directory contains the standalone HTTP/1.1 cross-server benchmark for Benchmark::Web.

No server is a dependency of Benchmark::Web. The runner discovers targets from `servers/*/server.pl`, skips unavailable targets by default, and only requires every requested target when `--strict` is used.

## Quick start

From `benchmarks/http/`:

```sh
perl run.pl --smoke
```

Run a selected comparison:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo,node,go,aiohttp \
  --requests=50000 \
  --warmup=5000 \
  --connections=100 \
  --repeats=5
```

Require every selected target to be available:

```sh
perl run.pl --servers=hyperman,feersum,node --smoke --strict
```

Write a machine-readable report:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo,node \
  --requests=100000 \
  --repeats=7 \
  --json=results/http-comparison.json
```

## Server runners

Each target lives in its own directory. Its README owns installation instructions, setup details, adapter-specific settings, and a one-target smoke-test command.

| key | server | selection | setup and adapter notes |
| --- | --- | --- | --- |
| `linuxevent` | Linux::Event::Net::HTTP | default | [servers/linuxevent/README.md](servers/linuxevent/README.md) |
| `hyperman` | Hyperman | default | [servers/hyperman/README.md](servers/hyperman/README.md) |
| `feersum` | Feersum | default | [servers/feersum/README.md](servers/feersum/README.md) |
| `mojo` | Mojolicious | default | [servers/mojo/README.md](servers/mojo/README.md) |
| `node` | Node.js built-in `http` | default | [servers/node/README.md](servers/node/README.md) |
| `go` | Go `net/http` | default | [servers/go/README.md](servers/go/README.md) |
| `aiohttp` | Python aiohttp | default | [servers/aiohttp/README.md](servers/aiohttp/README.md) |
| `twiggy` | Twiggy/AnyEvent | explicit-only | [servers/twiggy/README.md](servers/twiggy/README.md) |
| `h2o` | libh2o evloop | explicit-only | [servers/h2o/README.md](servers/h2o/README.md) |

Default target set:

```text
linuxevent,hyperman,feersum,mojo,node,go,aiohttp
```

The default set comes from metadata returned by each target's `server.pl info` action; it is not hard-coded in `run.pl`.

Twiggy is explicit-only because its current behavior does not complete this benchmark's long-lived keep-alive workload reliably. libh2o is explicit-only because it is a lower-level protocol/server reference rather than a peer application API.

## Workload contract

Every selected server is driven by the same raw client in `run.pl`.

Default request:

```text
GET /bench HTTP/1.1
Host: benchmark.test
```

Default response body: 32 bytes.

Every adapter returns HTTP 200 with a fixed `Content-Length` and an `application/octet-stream` body of exactly the requested size.

When `--request-body-bytes=N` is greater than zero, the client sends a POST with `Content-Length: N` and exactly N body bytes. Adapters consume the request body before returning the fixed response.

Each repeat:

1. starts a fresh server process;
2. opens the requested number of loopback TCP connections;
3. runs warmup requests without recording them;
4. runs the measured workload;
5. records throughput and client-visible latency;
6. stops the server;
7. rotates server order for the next repeat.

The primary comparison is a **single-process, single-application-execution-slot** benchmark. It is not a worker-scaling benchmark.

This is a protocol-stack comparison, not a claim that every framework performs identical application-layer work. Each adapter uses the smallest normal public API that receives the request and returns the same response shape. Server-specific choices are documented beside each adapter.

## Runner settings

### `--servers=LIST`

Comma-separated discovered server keys to run.

```sh
perl run.pl --servers=hyperman,feersum,node
```

With no `--servers`, the runner selects every discovered target whose `server.pl info` metadata has `default` enabled.

Unavailable targets are skipped unless `--strict` is used.

### `--requests=N`

Measured HTTP requests per server, per repeat.

Default: `20000`.

### `--warmup=N`

Unmeasured requests sent before each measured phase.

Default: `2000`.

Warmup exercises parser/runtime caches and establishes steady-state persistent connections.

### `--connections=N`

Number of simultaneous persistent TCP connections.

Default: `100`.

This changes concurrency, not total measured request count.

### `--pipeline=N`

Maximum outstanding HTTP/1.1 requests per connection.

Default: `1`.

`1` means no HTTP pipelining. Values above 1 intentionally benchmark pipelined HTTP/1.1.

Latency is measured from request write until the complete response is parsed, so queueing behind earlier pipelined requests is part of latency.

### `--request-body-bytes=N`

Fixed request body size.

Default: `0`.

`0` sends GET requests. Positive values send POST requests.

```sh
perl run.pl --servers=hyperman,feersum,mojo --request-body-bytes=4096
```

### `--response-bytes=N`

Fixed response body size returned by every adapter.

Default: `32`.

```sh
perl run.pl --response-bytes=65536
```

### `--repeats=N`

Complete measured runs per server.

Default: `5`.

Server order rotates between repeats. The summary reports medians rather than best-of values.

### `--timeout=SECONDS`

Maximum time allowed for server startup or a benchmark phase.

Default: `120`.

A timeout is a failed benchmark case, not a throughput result.

### `--strict`

Makes any requested unavailable server a fatal error. Use this for CI or published runs where silently omitting a target would invalidate the intended comparison.

`--no-strict` explicitly restores the default skip behavior.

### `--json=PATH`

Writes a machine-readable report containing the benchmark contract version, environment/runtime versions when detectable, complete configuration, per-target launcher metadata/settings, skipped targets, every repeat, and median summary values.

Keep the JSON report with published results.

### `--smoke`

Runs a tiny correctness workload:

```text
requests:        500
warmup:          100
connections:       4
pipeline:           1
response bytes:     8
repeats:            1
timeout:            15 seconds
```

Use smoke mode to verify setup and keep-alive behavior. Do not publish smoke throughput as performance data.

### `--help`

Prints the option summary and the server keys discovered from `servers/*/server.pl`.

## More examples

Higher concurrency:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo,node,go,aiohttp \
  --requests=100000 \
  --warmup=10000 \
  --connections=500 \
  --repeats=7
```

HTTP/1.1 pipelining:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo \
  --requests=100000 \
  --connections=100 \
  --pipeline=16 \
  --repeats=7
```

Large responses:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo \
  --response-bytes=65536 \
  --requests=50000
```

Optional low-level reference:

```sh
perl run.pl \
  --servers=hyperman,linuxevent,h2o \
  --requests=50000 \
  --warmup=5000 \
  --connections=100 \
  --repeats=5
```

## Directory layout

```text
README.md
run.pl
servers/
    aiohttp/
        README.md
        server.pl
        aiohttp-http.py
    feersum/
        README.md
        server.pl
        feersum-http.pl
    go/
        README.md
        server.pl
        go-http.go
    h2o/
        README.md
        server.pl
        libh2o-http.c
    hyperman/
        README.md
        server.pl
        hyperman-http.pl
    linuxevent/
        README.md
        server.pl
        linuxevent-http.pl
    mojo/
        README.md
        server.pl
        mojo-http.pl
    node/
        README.md
        server.pl
        node-http.js
    twiggy/
        README.md
        server.pl
        twiggy-http.pl
```

Each server directory owns its adapter source, setup documentation, dependency detection, build preparation, runtime configuration, and cleanup.

## Continuous integration

Repository CI uses small correctness workloads, including a required smoke comparison that does not select Linux::Event. Optional adapter CI may install benchmark targets temporarily to exercise their adapters; those installations are test fixtures, not Benchmark::Web dependencies.

CI also copies a conforming server directory to a brand-new key and runs it without changing `run.pl`. That protects the filesystem plug-in contract from accidentally becoming hard-coded later.

CI throughput is not a publishable performance result.

## Interpreting results

The runner reports requests per second plus p50, p95, p99, and maximum client-visible latency. The final table uses the median value across repeats for each metric.

The screenshot-oriented terminal summary includes the common workload settings plus the short `settings` string reported by each selected target launcher. Server-specific configuration therefore stays owned by the server folder while remaining visible in shared results.

Loopback throughput is useful for comparing CPU/protocol-stack cost, but it is not internet request capacity. Real network latency and bandwidth are deliberately absent, and client plus server compete for resources on one machine.

For public results:

- use a quiet stable machine or dedicated runner;
- report CPU model, OS/kernel, and runtime/server versions;
- keep workload settings identical;
- use multiple repeats and report medians;
- do not compare one-worker with multi-worker results as if they were the same benchmark;
- avoid unrelated CPU/network work;
- retain the JSON report;
- distinguish directional shared-CI results from dedicated-machine measurements.

GitHub-hosted runner throughput is useful for regression direction and correctness, but absolute numbers can vary substantially between runner instances.

## Server launcher contract

Every immediate subdirectory of `servers/` that contains `server.pl` is a benchmark target. The directory name is its runner key.

`run.pl` invokes every target through the same interface:

```text
server.pl info
server.pl probe
server.pl prepare
server.pl version
server.pl settings
server.pl run
server.pl cleanup
```

The actions mean:

- `info` prints one JSON object with at least `label`; `default` selects whether the target joins the default matrix, and `order` controls stable display order.
- `probe` exits zero when the target can be used on this machine and nonzero otherwise.
- `prepare` performs target-specific setup such as compiling a temporary helper binary. It exits zero on success.
- `version` prints the target/runtime version used for the JSON report.
- `settings` prints a short human-readable summary of fairness-relevant target setup. It is included in the terminal summary and JSON report.
- `run` starts the server and does not return until the benchmark terminates it.
- `cleanup` removes temporary target-specific build artifacts and should succeed when there is nothing to remove.

`run.pl` supplies the benchmark workload inputs uniformly through `BENCH_PORT`, `BENCH_RESPONSE_BYTES`, and `BENCH_REQUEST_BODY_BYTES` when it invokes `run`. Those are part of the benchmark launcher contract. Any additional environment variables, runtime flags, build commands, source-checkout discovery, or other setup required by a particular implementation belongs inside that implementation's `server.pl`, not in `run.pl`.

`prepare` and `run` are separate launcher invocations, so environment changes made by `prepare` do not carry into the server process. If a target requires runtime environment variables, its `run` action must set them itself before launching the implementation.

A contributor may use any files they need inside their own server directory. Only `server.pl` and the benchmark protocol contract are visible to the central runner. A conforming new directory becomes selectable with `--servers=<key>` without a registration edit to `run.pl`.

## Adapter contract

Contributions from server authors are welcome.

A primary-comparison adapter should:

1. listen on `127.0.0.1:$ENV{BENCH_PORT}`;
2. use `$ENV{BENCH_RESPONSE_BYTES}` for the fixed body size;
3. consume a request body before responding;
4. return HTTP 200 with a fixed `Content-Length`;
5. use one server process and one application execution slot;
6. disable access logging, compression, TLS, and unrelated middleware;
7. use the smallest normal public API of the server being measured.

If a server cannot satisfy one of those constraints, document the difference in that server's README rather than hiding it.
