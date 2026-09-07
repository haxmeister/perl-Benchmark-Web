# HTTP server comparison

This directory contains the standalone HTTP/1.1 comparison benchmark for Benchmark::Web.

You can point users directly at this folder. It contains the runner, every server adapter, and the full benchmark contract.

**No server is required to use the benchmark.** Missing competitors are skipped unless `--strict` is requested.

In particular, Linux::Event::Net::HTTP and Hyperman are optional benchmark targets, not dependencies of Benchmark::Web.

## Current server keys

| key | server | requirement |
| --- | --- | --- |
| `linuxevent` | Linux::Event::Net::HTTP | installed modules or `BENCH_LINUXEVENT_ROOT` |
| `hyperman` | Hyperman | Perl module `Hyperman` |
| `feersum` | Feersum | Perl module `Feersum` |
| `mojo` | Mojolicious | Perl module `Mojolicious` |
| `twiggy` | Twiggy/AnyEvent | Perl module `Twiggy`; explicit-only |
| `node` | Node.js built-in `http` | `node` executable |
| `go` | Go `net/http` | Go toolchain |
| `aiohttp` | Python aiohttp | Python 3 plus `aiohttp` |
| `h2o` | libh2o evloop | compiler, `pkg-config`, `libh2o-evloop`; explicit-only |

Default set:

```text
linuxevent,hyperman,feersum,mojo,node,go,aiohttp
```

Any unavailable member is reported as `skipped=` and the remaining servers still run.

Twiggy is explicit-only because current Twiggy closes the long-lived keep-alive connections used by this workload before the requested phase completes. libh2o is explicit-only because it is a lower-level reference implementation rather than a peer application API.

## Quick start

From this directory:

```sh
perl run.pl --smoke
```

Hyperman only:

```sh
perl run.pl \
  --servers=hyperman \
  --requests=50000 \
  --warmup=5000 \
  --connections=100 \
  --repeats=5
```

Perl servers without Linux::Event:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo \
  --requests=50000 \
  --warmup=5000 \
  --connections=100 \
  --repeats=5
```

All installed default competitors:

```sh
perl run.pl
```

## Optional competitor installation

Perl competitors:

```sh
cpanm Hyperman Feersum Mojolicious
```

Twiggy, only when explicitly selected:

```sh
cpanm Twiggy
```

Python aiohttp in an isolated environment:

```sh
python3 -m venv .venv
.venv/bin/pip install aiohttp
PATH="$PWD/.venv/bin:$PATH" perl run.pl --servers=aiohttp --smoke
```

Node.js and Go are detected from `PATH`.

On Debian/Ubuntu, optional libh2o reference support can typically be enabled with:

```sh
sudo apt-get install build-essential pkg-config libh2o-evloop-dev
perl run.pl --servers=h2o --smoke
```

These commands install benchmark targets for the person running the benchmark. They are not Benchmark::Web package dependencies.

## Linux::Event source checkout

An installed Linux::Event::Net::HTTP is detected through the normal Perl module path.

To benchmark an uninstalled development checkout, build it normally and point the runner to it:

```sh
cd /path/to/perl-Linux-Event-Net-HTTP
perl Makefile.PL
make

cd /path/to/perl-Benchmark-Web/benchmarks/http
BENCH_LINUXEVENT_ROOT=/path/to/perl-Linux-Event-Net-HTTP \
  perl run.pl --servers=linuxevent,hyperman,feersum --smoke
```

If Linux::Event is neither installed nor supplied with `BENCH_LINUXEVENT_ROOT`, it is skipped unless `--strict` is used.

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

Hyperman runs with `workers => 1`, which its documented API defines as in-process mode without the prefork supervisor. Compression is disabled explicitly. Go uses `GOMAXPROCS=1`. Other adapters likewise use one server process and their normal single-loop/single-slot mode.

This is a protocol-stack comparison, not a claim that every framework performs identical application-layer work. Each adapter uses the smallest normal public API that receives the request and returns the same response shape.

## Settings

### `--servers=LIST`

Comma-separated server keys to run.

```sh
perl run.pl --servers=hyperman,feersum,node
```

Default:

```text
linuxevent,hyperman,feersum,mojo,node,go,aiohttp
```

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

By default unavailable competitors are skipped.

`--strict` makes any requested unavailable server a fatal error. This is useful for CI or published runs where silently omitting a target would invalidate the intended comparison.

```sh
perl run.pl --servers=hyperman,feersum,mojo --strict
```

### `--json=PATH`

Writes a machine-readable report containing:

- benchmark contract version;
- OS, kernel, architecture, and runtime/framework versions when detectable;
- complete benchmark configuration;
- available and skipped servers;
- every repeat;
- median summary values.

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo,node \
  --requests=100000 \
  --repeats=7 \
  --json=results/http-comparison.json
```

Keep the JSON report with published results.

### `--smoke`

Tiny correctness workload:

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

Explicitly omit Linux::Event:

```sh
perl run.pl --servers=hyperman,feersum,mojo,node,go,aiohttp
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

## Linux::Event development modes

The Linux::Event adapter recognizes `BENCH_LINUXEVENT_MODE`:

```text
natural       ordinary on_request -> Response->end
request-end   response completed from on_request_end
fast-final    on_request_final default-final path
```

Example:

```sh
BENCH_LINUXEVENT_MODE=fast-final \
BENCH_LINUXEVENT_ROOT=/path/to/perl-Linux-Event-Net-HTTP \
  perl run.pl --servers=linuxevent,hyperman,feersum
```

This variable changes only the Linux::Event adapter. Do not mix different Linux::Event modes into one published result without labeling them separately.

## Interpreting results

The runner reports:

- requests per second;
- p50 client-visible latency;
- p95 latency;
- p99 latency;
- maximum latency.

The final table uses the median value across repeats for each metric.

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

If a server cannot satisfy one of those constraints, document the difference rather than hiding it.
