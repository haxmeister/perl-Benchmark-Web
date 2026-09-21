# WebSocket application comparison

This benchmark family compares WebSocket server implementations under one
shared application-style request/acknowledgement workload.

It is deliberately not an echo benchmark. Every server receives the same text
message, performs the same small application-level validation, and sends the
same fixed acknowledgement.

No benchmarked server is a dependency of Benchmark::Web. Targets are discovered
from `servers/*/server.pl` and unavailable targets are skipped unless
`--strict` is requested.

## Quick start

From `benchmarks/websocket/`:

```sh
npm install
perl run.pl --smoke
```

A normal comparison:

```sh
perl run.pl \
  --servers=linuxevent,mojo,nodews,gorilla \
  --bytes=256 \
  --connections=100 \
  --window=4 \
  --seconds=5 \
  --repeats=5
```

A one-request-at-a-time latency-sensitive comparison:

```sh
perl run.pl --connections=1000 --window=1 --bytes=64 --repeats=5
```

A more throughput-oriented comparison:

```sh
perl run.pl --connections=1000 --window=16 --bytes=64 --repeats=5
```

Write a machine-readable report:

```sh
perl run.pl --connections=1000 --window=4 --json=results/websocket.json
```

## Current adapters

| key | implementation | normal server API |
| --- | --- | --- |
| `linuxevent` | Linux::Event::WebSocket | Linux::Event::WebSocket::Server |
| `mojo` | Mojolicious | websocket route |
| `nodews` | Node.js + ws | WebSocketServer |
| `gorilla` | Go + gorilla/websocket | Upgrader + Conn |

Every adapter is optional. Its launcher owns dependency detection and any
temporary preparation.

## Workload contract

The shared client opens the requested number of WebSocket connections to
`/application`.

Every request is a text WebSocket message of exactly `--bytes` bytes. It starts
with a JSON-like application prefix and contains a room, body, and sequence
field. The benchmark does not ask the server to parse full JSON because parser
choice would become a separate benchmark variable. Instead every adapter:

1. receives a complete WebSocket text message through its normal public API;
2. verifies that the message begins with `{"op":`;
3. sends the fixed text acknowledgement `{"ok":true}`.

The shared client validates every acknowledgement.

`--window=N` controls the maximum number of outstanding requests per
connection. Window 1 is intentionally sensitive to per-roundtrip scheduling and
dispatch cost. Larger windows expose how effectively the implementation
amortizes fixed per-event and per-write overhead.

Per-message deflate is disabled. TLS is not part of this benchmark.

The primary comparison is one server process and one application execution
slot. The Go adapter sets `GOMAXPROCS=1`.

## Runner options

- `--servers=LIST`: discovered server keys.
- `--bytes=N`: request text-message size. Default 256.
- `--connections=N`: simultaneous WebSocket connections. Default 100.
- `--window=N`: outstanding requests per connection. Default 4.
- `--warmup=SECONDS`: unmeasured warmup. Default 0.75.
- `--seconds=SECONDS`: measured duration. Default 3.
- `--repeats=N`: complete runs per target. Default 5.
- `--timeout=SECONDS`: startup/client timeout. Default 120.
- `--strict`: fail rather than skip unavailable targets.
- `--json=PATH`: retain machine-readable results.
- `--smoke`: tiny correctness run.
- `--help`: print discovered targets and options.

Server order rotates between repeats. The terminal summary reports the median
transaction rate across repeats.

## Client dependency

The shared load generator uses Node.js and the `ws` package. Install it once
inside this benchmark family with:

```sh
npm install
```

Using one client implementation for every target keeps the wire workload
identical. The client is not counted as one of the server adapters.

## Interpreting results

This workload measures a complete public WebSocket application path:

```text
socket read
  -> WebSocket frame parsing
  -> text delivery
  -> application callback
  -> acknowledgement framing
  -> socket write
  -> client acknowledgement
```

It does not isolate parser throughput, raw socket throughput, broadcast fan-out,
compression, TLS, or multi-worker scaling. Those deserve separate workload
contracts if added later.

Window 1 and window 4/16 answer different questions. Do not collapse them into
one ranking. A server may have excellent sustained throughput but higher
one-request-at-a-time turnaround cost.

For public results, retain the JSON report and record CPU, OS/kernel, runtime
versions, target settings, exact connection/window/message-size settings, and
multiple repeats.

## Server launcher contract

Each immediate subdirectory of `servers/` containing `server.pl` is a target.
Launchers implement:

```text
server.pl info
server.pl probe
server.pl prepare
server.pl version
server.pl settings
server.pl run
server.pl cleanup
```

The runner supplies `BENCH_PORT`. The application request/ack contract is fixed
by this benchmark family.

A normal adapter should listen on `127.0.0.1:$ENV{BENCH_PORT}`, expose
`/application`, disable compression and unrelated middleware, use one server
process and one application execution slot, and use the implementation's normal
public WebSocket API.
