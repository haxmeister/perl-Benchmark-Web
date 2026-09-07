# Linux::Event::Net::HTTP benchmark target

Runner key: `linuxevent`

Adapter: `linuxevent-http.pl`

This target benchmarks Linux::Event::Net::HTTP using one event loop and one server process.

## Recommended install

`Linux::Event` is available from CPAN. `Linux::Event::Net::HTTP` is **not** assumed to be a CPAN distribution; Benchmark::Web obtains that code from its GitHub repository.

The recommended setup is therefore target-local and does not install either component globally.

On Debian/Ubuntu/Devuan, install the ordinary build tools and `cpanm`:

```sh
sudo apt update
sudo apt install build-essential git cpanminus
```

Then, from this directory:

```sh
bash install.sh
```

The installer:

1. installs the current CPAN `Linux::Event` into `servers/linuxevent/.local/`;
2. clones `haxmeister/perl-Linux-Event-Net-HTTP` into `servers/linuxevent/.source/http/`;
3. builds the HTTP distribution against that target-local `Linux::Event`;
4. verifies that `server.pl` can load the resulting runtime.

The `cpanm` script is executed through the same `perl` found in your current shell. This matters on perlbrew and similar installations because XS modules must be built for the Perl that will run the benchmark.

No `PERL5LIB`, `BENCH_LINUXEVENT_ROOT`, or other installation environment variable needs to be exported. `server.pl` adds the target-local CPAN library and HTTP `blib` directories itself.

The generated `.local/` and `.source/` trees are ignored by Git.

After installation, verify detection:

```sh
perl server.pl probe
perl server.pl version
perl server.pl settings
```

Then run from `benchmarks/http/`:

```sh
perl run.pl --servers=linuxevent --smoke --strict
```

To build a particular branch or tag of the HTTP repository instead of `main`, pass it as the first argument:

```sh
bash install.sh branch-or-tag
```

## Why the installer is split this way

`Linux::Event::Net::HTTP` declares `Linux::Event >= 0.112` as a prerequisite, but the two components have different distribution status:

- `Linux::Event` is installed from CPAN.
- `Linux::Event::Net::HTTP` is cloned and built from its source repository.

Benchmark::Web does not add either one as a project dependency. They are setup for this benchmark target only.

## Existing installations

If both required module sets are already available to the Perl running Benchmark::Web, `server.pl` can use them directly and `install.sh` is unnecessary.

The target-local installer is preferred for a reproducible benchmark setup because it keeps the HTTP checkout and its CPAN prerequisite isolated inside this server folder.

## Development checkout

`server.pl` can also benchmark an already-built HTTP checkout without installing it.

If `perl-Benchmark-Web` and `perl-Linux-Event-Net-HTTP` are sibling directories, the launcher detects the HTTP checkout automatically:

```text
work/
    perl-Benchmark-Web/
    perl-Linux-Event-Net-HTTP/
```

Build that checkout normally against an available `Linux::Event`:

```sh
cd /path/to/work/perl-Linux-Event-Net-HTTP
perl Makefile.PL
make
```

Then run the benchmark normally. If `servers/linuxevent/.local/` exists, the launcher can use its target-local CPAN `Linux::Event` together with the external HTTP checkout.

If the HTTP checkout is elsewhere, put its path in the target-local `source-root` file:

```sh
printf '%s\n' /path/to/perl-Linux-Event-Net-HTTP \
  > servers/linuxevent/source-root
```

`source-root` is a development override only. It is ignored by Git and does not require an environment variable.

## Adapter modes

The normal matrix uses `natural` mode and `read_budget_bytes=0`; `server.pl` applies those defaults itself.

For development comparisons, `BENCH_LINUXEVENT_MODE` can override the response path:

```text
natural       ordinary on_request -> Response->end
request-end   response completed from on_request_end
fast-final    on_request_final default-final path
```

`BENCH_READ_BUDGET_BYTES` can likewise override the connection class `read_budget_bytes` stream option. These are benchmark-development settings rather than installation requirements. The selected values and runtime source are reported by the generic `settings` action and therefore appear in the terminal summary and JSON output.

For requests with bodies, `natural` defers the response until `on_request_end` so the body is consumed before responding.

Do not mix Linux::Event modes in one published result without labeling them separately.

## Launcher interface

This directory is self-contained behind `server.pl`. The central HTTP runner discovers this directory automatically and uses the standard `info`, `probe`, `prepare`, `version`, `settings`, `run`, and `cleanup` actions. Target-specific setup belongs here; `run.pl` does not contain special cases for Linux::Event.
