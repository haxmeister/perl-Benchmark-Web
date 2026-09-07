# Node.js benchmark target

Runner key: `node`

Adapter: `node-http.js`

This target uses Node.js's built-in `node:http` module. There are no npm dependencies.

## Install

Install a current Node.js runtime using your operating system or Node.js distribution method. On Debian/Devuan systems, the distribution package is typically:

```sh
sudo apt update
sudo apt install nodejs
```

Verify it:

```sh
node --version
```

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=node --smoke --strict
```

## Adapter setup

The runner launches one Node.js process. The adapter uses only `node:http`, consumes the incoming request stream, and sends the fixed benchmark response after the request body ends.
\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n