# Go net/http benchmark target

Runner key: `go`

Adapter: `go-http.go`

This target uses only Go's standard `net/http` package. There are no third-party Go modules.

## Install

Install the Go toolchain. On Debian/Devuan systems:

```sh
sudo apt update
sudo apt install golang-go
```

Verify it:

```sh
go version
```

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=go --smoke --strict
```

`run.pl` compiles `go-http.go` to a temporary binary before the benchmark and removes that binary afterward.

## Adapter setup

The adapter calls `runtime.GOMAXPROCS(1)` so the comparison remains one application execution slot. It uses the standard `net/http` server, drains request bodies, and returns the fixed response payload.
