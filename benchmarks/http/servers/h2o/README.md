# libh2o evloop benchmark target

Runner key: `h2o`

Adapter: `libh2o-http.c`

This target is explicit-only. It measures libh2o's native event-loop HTTP server API as a lower-level reference implementation rather than a peer application framework.

## Recommended install

Do not depend on a distribution package named `libh2o-evloop-dev`. That package exists in some Debian-derived releases and is absent in others. Benchmark::Web therefore uses a target-local source build as its primary setup path.

Nothing is installed into `/usr` or `/usr/local`, and no H2O-specific environment variable needs to be exported.

On Debian/Ubuntu/Devuan, install only the build prerequisites:

```sh
sudo apt update
sudo apt install build-essential cmake pkg-config libssl-dev zlib1g-dev git
```

Then, from `benchmarks/http/servers/h2o/`:

```sh
sh install.sh
```

The installer clones current upstream H2O `master` with its required submodules, builds `libh2o-evloop` as a shared library, and installs the result under:

```text
benchmarks/http/servers/h2o/.local/
```

The corresponding source and build trees are kept under `.source/` and `.build/`. All three paths are ignored by Git.

The launcher automatically searches the target-local pkg-config directories before system locations. You do **not** need to set `PKG_CONFIG_PATH` or `LD_LIBRARY_PATH`.

After installation, verify detection from `benchmarks/http/servers/h2o/`:

```sh
perl server.pl probe
perl server.pl version
```

Then run the benchmark from `benchmarks/http/`:

```sh
perl run.pl --servers=h2o --smoke --strict
```

The installer defaults to current upstream `master`, which is the upstream H2O project's normal development/release line. If you intentionally want another existing branch or tag, pass its name as the first argument to `install.sh`.

## Why not install `libh2o-evloop-dev`?

`libh2o-evloop-dev` is release-dependent and may not exist in the package repositories on the machine running the benchmark. Requiring it would make the benchmark unnecessarily dependent on distribution packaging choices.

If your system already provides a compatible `libh2o-evloop` development installation, `server.pl` can still use it through normal pkg-config discovery. The target-local install is recommended because it behaves consistently across distributions.

## What the local build enables

The source installer builds H2O's shared libraries in Release mode and disables unrelated optional features including mruby, Brotli, zstd, AEGIS, io_uring, Fusion AES-GCM, and KTLS. The benchmark needs the normal `libh2o-evloop` HTTP server API, not those optional integrations.

A shared `libh2o-evloop` is intentional. Current upstream pkg-config metadata identifies the H2O library itself but does not enumerate all transitive dependencies needed to link a static archive. The shared library records those dependencies itself and avoids maintaining an out-of-tree copy of H2O's linker configuration.

Upstream H2O's CMake install supplies `libh2o-evloop.pc`, the H2O headers, and the evloop shared library under the target-local prefix. `server.pl prepare` uses pkg-config to compile `libh2o-http.c` and embeds an rpath to the detected H2O library directory, so the temporary benchmark executable can find the target-local library without modifying the shell environment.

## Adapter setup

`server.pl prepare` compiles `libh2o-http.c` to a temporary binary using the flags returned by:

```text
pkg-config --cflags --libs libh2o-evloop
```

It also obtains `libdir` from pkg-config and embeds that directory as the executable's runtime library search path. `server.pl cleanup` removes the temporary benchmark binary after the run.

A successful `probe` means the required compiler and library metadata were found. If `prepare` fails, the runner reports the target as unavailable; compile/link compatibility belongs to this target folder rather than to `run.pl`.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs in this directory; `run.pl` does not contain special cases for H2O.
