# libh2o evloop benchmark target

Runner key: `h2o`

Adapter: `libh2o-http.c`

This target is explicit-only. It measures libh2o's native event-loop HTTP server API as a lower-level reference implementation rather than a peer application framework.

## Required library

The runner requires a C compiler, `pkg-config`, and an installed `libh2o-evloop` that is visible through:

```sh
pkg-config --modversion libh2o-evloop
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

Verify the library required by Benchmark::Web:

```sh
pkg-config --modversion libh2o-evloop
```

If H2O was installed under a custom prefix and `pkg-config` cannot find it, add the prefix's `lib/pkgconfig` directory to `PKG_CONFIG_PATH`. For the common `/usr/local` prefix:

```sh
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
pkg-config --modversion libh2o-evloop
```

If your distribution actually provides `libh2o-evloop-dev`, installing that package together with `build-essential` and `pkg-config` is a valid shortcut. Check first with:

```sh
apt-cache show libh2o-evloop-dev
```

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=h2o --smoke --strict
```

The runner compiles `libh2o-http.c` to a temporary binary using the flags returned by `pkg-config --cflags --libs libh2o-evloop`.

## Compatibility note

A successful `pkg-config --modversion libh2o-evloop` proves that the library installation is visible to the benchmark. If the adapter's compile/link step then fails, that is a libh2o API/ABI compatibility problem in the adapter rather than an installation-detection failure. Current upstream compatibility is tracked separately from these installation instructions.
