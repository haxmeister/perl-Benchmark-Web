# Python aiohttp benchmark target

Runner key: `aiohttp`

Adapter: `aiohttp-http.py`

## Install

A virtual environment keeps the benchmark dependency out of the system Python installation. On Debian/Devuan systems:

```sh
sudo apt update
sudo apt install python3 python3-venv
```

From `benchmarks/http/` create the environment and install aiohttp:

```sh
python3 -m venv .venv
.venv/bin/pip install aiohttp
```

Verify it:

```sh
.venv/bin/python -c 'import aiohttp; print(aiohttp.__version__)'
```

The benchmark runner invokes `python3`, so put the virtual environment first in `PATH` when running this target:

```sh
PATH="$PWD/.venv/bin:$PATH" perl run.pl --servers=aiohttp --smoke --strict
```

Benchmark::Web does not depend on aiohttp. The virtual environment is only a local benchmark setup.

## Adapter setup

The adapter uses `aiohttp.web`, disables access logging, consumes request bodies, and returns the fixed benchmark response from `/bench`.
\n## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.\n