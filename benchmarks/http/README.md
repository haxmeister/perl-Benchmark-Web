# HTTP server comparison

This directory contains the standalone HTTP/1.1 cross-server benchmark for Benchmark::Web.

No server is a dependency of Benchmark::Web. The runner detects the targets available on the machine, skips missing targets by default, and only requires every requested target when `--strict` is used.

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

Comma-separated server keys to run.

```sh
perl run.pl --servers=hyperman,feersum,node
```

Default:

```text
linuxevent,hyperman,feersum,mojo,node,go,aiohttp
```

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

Writes a machine-readable report containing the benchmark contract version, environment/runtime versions when detectable, complete configuration, skipped targets, every repeat, and median summary values.

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

Prints the option summary.

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
    feersum/
    go/
    h2o/
    hyperman/
    linuxevent/
    mojo/
    node/
    twiggy/
```

Each server directory contains the adapter source and its README.

## Continuous integration

Repository CI uses small correctness workloads, including a required smoke comparison that does not select Linux::Event. Optional adapter CI may install benchmark targets temporarily to exercise their adapters; those installations are test fixtures, not Benchmark::Web dependencies.

CI throughput is not a publishable performance result.

## Interpreting results

The runner reports requests per second plus p50, p95, p99, and maximum client-visible latency. The final table uses the median value across repeats for each metric.

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
