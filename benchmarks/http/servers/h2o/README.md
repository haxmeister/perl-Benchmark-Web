# libh2o evloop benchmark target

Runner key: `h2o`

Adapter: `libh2o-http.c`

This target is explicit-only. It measures libh2o's native event-loop HTTP server API as a lower-level reference implementation rather than a peer application framework.

## Required library

The target requires a C compiler, `pkg-config`, and an installed `libh2o-evloop`.

`server.pl` handles the common `/usr/local` pkg-config locations itself, including multiarch subdirectories, so normal source installs do not require exporting `PKG_CONFIG_PATH`.

You can check whether the target can see the library with:

```sh
perl servers/h2o/server.pl probe
```

or, from this directory:

```sh
perl server.pl probe
```

The `libh2o-evloop-dev` package is not available on every Debian-derived release, so do not assume that package name exists on a particular Debian, Ubuntu, or Devuan release.

## Build current upstream H2O

On Debian/Ubuntu/Devuan systems, install the build prerequisites:

```sh
sudo apt update
sudo apt install build-essential cmake pkg-config libssl-dev zlib1g-dev git
```

Clone H2O with its submodules and install it:

```sh
git clone --recurse-submodules https://github.com/h2o/h2o.git
cd h2o
mkdir -p build
cd build
cmake ..
make -j"$(nproc)"
sudo make install
sudo ldconfig
```

After installation, return to `benchmarks/http/` and let the target launcher perform detection and compilation:

```sh
perl run.pl --servers=h2o --smoke --strict
```

If your distribution actually provides `libh2o-evloop-dev`, installing that package together with `build-essential` and `pkg-config` is also valid. Check first with:

```sh
apt-cache show libh2o-evloop-dev
```

## Adapter setup

`server.pl prepare` compiles `libh2o-http.c` to a temporary binary using the flags returned by `pkg-config --cflags --libs libh2o-evloop`. `server.pl cleanup` removes that binary after the benchmark.

A successful `probe` means the required compiler and library metadata were found. If `prepare` fails, the runner reports the target as unavailable; compile/link compatibility belongs to this target folder rather than to `run.pl`.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in `server.pl`; `run.pl` does not contain special cases for this server.
