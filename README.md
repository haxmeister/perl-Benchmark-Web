# Benchmark::Web

A standalone, reproducible HTTP server comparison benchmark.

This repository exists so HTTP server authors and users can run the same raw-client workload against multiple implementations and contribute new adapters without depending on any one server project.

**No benchmark competitor is a project dependency.** Linux::Event::Net::HTTP, Hyperman, Feersum, Mojolicious, Twiggy, Node.js, Go, aiohttp, and libh2o are all optional. Missing competitors are skipped unless `--strict` is requested.

## Quick start

```sh
perl run.pl --smoke
```

Compare Hyperman with other Perl servers without Linux::Event installed:

```sh
perl run.pl \
  --servers=hyperman,feersum,mojo \
  --requests=50000 \
  --warmup=5000 \
  --connections=100 \
  --repeats=5
```

See [docs/HTTP-COMPARISON.md](docs/HTTP-COMPARISON.md) for the benchmark contract, every setting, installation examples, fairness rules, and guidance for publishing results.

## Current HTTP/1.1 adapters

- Linux::Event::Net::HTTP
- Hyperman
- Feersum
- Mojolicious
- Twiggy/AnyEvent (explicit-only)
- Node.js `http`
- Go `net/http`
- Python aiohttp
- libh2o evloop (explicit-only reference)

## Contributing

New server adapters are welcome. An adapter should:

1. listen on `127.0.0.1:$ENV{BENCH_PORT}`;
2. consume the complete request body before responding;
3. return HTTP 200 with exactly `$ENV{BENCH_RESPONSE_BYTES}` bytes;
4. use a fixed `Content-Length`;
5. run one server process and one application execution slot for the primary comparison;
6. avoid access logging, compression, TLS, or unrelated middleware unless that is the benchmark being studied;
7. use the smallest normal public API of the server being measured.

Add the adapter under `servers/`, register it in `run.pl`, document any runtime requirements, and verify it with `perl run.pl --servers=yourserver --smoke --strict`.

Please keep benchmark dependencies optional. Do not add a server implementation as a required dependency of this repository merely so its adapter can run.
