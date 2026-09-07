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

`server.pl prepare` compiles `go-http.go` to a temporary binary before the benchmark and `server.pl cleanup` removes that binary afterward.

## Adapter setup

The launcher sets `GOMAXPROCS=1`, and the adapter also calls `runtime.GOMAXPROCS(1)`, so the comparison remains one application execution slot. The adapter uses the standard `net/http` server, drains request bodies, and returns the fixed response payload.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.
