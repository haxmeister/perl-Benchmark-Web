# libh2o evloop benchmark target

Runner key: `h2o`

Adapter: `libh2o-http.c`

This target is explicit-only. It measures libh2o's native event-loop HTTP server API as a lower-level reference implementation rather than a peer application framework.

## Recommended install

Do not depend on a distribution package named `libh2o-evloop-dev`. That package is not available on every Debian-derived release, including current Devuan releases whose package set follows newer Debian suites.

The supported Benchmark::Web setup is a target-local source build. Nothing is installed into `/usr` or `/usr/local`, and no H2O-specific environment variable needs to be exported.

On Debian/Ubuntu/Devuan, install only the build prerequisites:

```sh
sudo apt update
sudo apt install build-essential cmake pkg-config libssl-dev zlib1g-dev git
```

Then, from this directory:

```sh
bash install.sh
```

`install.sh` clones current upstream H2O with its required submodules, builds a reduced source configuration suitable for this benchmark, and installs it under:

```text
servers/h2o/.local/
```

The corresponding source and build trees are kept under `.source/` and `.build/`. All three paths are ignored by Git.

The launcher automatically searches the target-local pkg-config directories before system locations. You do **not** need to set `PKG_CONFIG_PATH`.

After installation, verify detection:

```sh
perl server.pl probe
perl server.pl version
```

Then run the benchmark from `benchmarks/http/`:

```sh
perl run.pl --servers=h2o --smoke --strict
```

To build a particular upstream branch or tag instead of `master`, pass it as the first argument:

```sh
bash install.sh v2.3.0
```

Use a branch or tag that exists in the upstream H2O repository.

## Why not install `libh2o-evloop-dev`?

Some older Debian/Ubuntu releases package H2O's development library as `libh2o-evloop-dev`, but that package is release-dependent and may be absent entirely. Benchmark::Web therefore does not use it as the primary installation path.

If your distribution already provides a compatible `libh2o-evloop` development package, `server.pl` can still use it through normal `pkg-config` discovery. The target-local install is preferred because it works independently of distribution packaging.

## What the local build enables

The source installer explicitly builds H2O's libraries and disables unrelated optional features such as mruby, Brotli, AEGIS, io_uring, and Fusion. The benchmark needs `libh2o-evloop`, not the full set of optional standalone-server integrations.

Upstream H2O's CMake install supplies `libh2o-evloop.pc`, the H2O headers, and the evloop library under the target-local prefix. `server.pl prepare` then compiles `libh2o-http.c` using:

```text
pkg-config --cflags --libs libh2o-evloop
```

## Adapter setup

`server.pl prepare` compiles `libh2o-http.c` to a temporary binary using the flags returned by pkg-config. `server.pl cleanup` removes that temporary benchmark binary after the run.

A successful `probe` means the required compiler and library metadata were found. If `prepare` fails, the runner reports the target as unavailable; compile/link compatibility belongs to this target folder rather than to `run.pl`.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in this directory; `run.pl` does not contain special cases for H2O.
