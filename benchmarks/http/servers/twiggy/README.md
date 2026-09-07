# Twiggy benchmark target

Runner key: `twiggy`

Adapter: `twiggy-http.pl`

This target is explicit-only and is not part of the default comparison set.

## Install

Install Twiggy with your normal CPAN client:

```sh
cpanm Twiggy
```

Twiggy will install its normal AnyEvent dependencies.

Verify it:

```sh
perl -MTwiggy -e 'print "$Twiggy::VERSION\n"'
```

## Run

From `benchmarks/http/`:

```sh
perl run.pl --servers=twiggy --smoke --strict
```

## Current benchmark status

Twiggy is explicit-only because current Twiggy behavior closes the long-lived keep-alive connections used by this workload before the requested phase completes reliably. Keep that limitation attached to Twiggy-specific results rather than treating an incomplete run as comparable throughput.

The adapter uses `Twiggy::Server` directly and consumes request bodies before returning the fixed PSGI response.
