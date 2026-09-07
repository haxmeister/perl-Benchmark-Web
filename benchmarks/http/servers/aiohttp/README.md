# Python aiohttp benchmark target

Runner key: `aiohttp`

Adapter: `aiohttp-http.py`

## Install

A virtual environment keeps aiohttp isolated from the system Python installation. On Debian/Devuan systems:

```sh
sudo apt update
sudo apt install python3 python3-venv
```

Create the target-local virtual environment inside this server directory:

```sh
cd benchmarks/http/servers/aiohttp
python3 -m venv .venv
.venv/bin/pip install aiohttp
```

Verify it:

```sh
.venv/bin/python3 -c 'import aiohttp; print(aiohttp.__version__)'
```

`server.pl` automatically prefers `servers/aiohttp/.venv/bin/python3` when it exists and otherwise falls back to the system `python3`. No `PATH` or other environment-variable setup is required.

Benchmark::Web does not depend on aiohttp. The virtual environment is only local setup for this benchmark target.

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=aiohttp --smoke --strict
```

## Adapter setup

The adapter uses `aiohttp.web`, disables access logging, consumes request bodies, and returns the fixed benchmark response from `/bench`.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.
