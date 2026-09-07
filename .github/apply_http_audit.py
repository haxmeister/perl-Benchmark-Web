from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, found {count}")
    file.write_text(text.replace(old, new, 1))


replace_once(
    "benchmarks/http/run.pl",
    r'''                my $body_len = 0 + $1;
                last if length($s->{buffer}) < $head_len + $body_len;
''',
    r'''                my $body_len = 0 + $1;
                die "benchmark response Content-Length $body_len did not match configured response bytes $response_bytes\n"
                    if $body_len != $response_bytes;
                last if length($s->{buffer}) < $head_len + $body_len;
''',
)

replace_once(
    "benchmarks/http/servers/feersum-http.pl",
    r'''$runner->run(sub ($request) {
    $request->send_response(
        200,
        ['Content-Type' => 'application/octet-stream'],
        \$payload,
    );
    return;
});
''',
    r'''$runner->run(sub ($request) {
    my $remaining = 0 + ($request->content_length // 0);
    if ($remaining > 0) {
        my $input = $request->input;
        die "missing benchmark request body\n" if !defined $input;
        while ($remaining > 0) {
            my $want = $remaining > 65_536 ? 65_536 : $remaining;
            my $chunk = '';
            my $n = $input->read($chunk, $want);
            die "short benchmark request body\n"
                if !defined($n) || $n <= 0;
            $remaining -= $n;
        }
        $input->close;
    }

    $request->send_response(
        200,
        [
            'Content-Type'   => 'application/octet-stream',
            'Content-Length' => length($payload),
        ],
        \$payload,
    );
    return;
});
''',
)

replace_once(
    "benchmarks/http/servers/twiggy-http.pl",
    r'''        my $input = $env->{'psgi.input'};
        while ($remaining > 0) {
            my $buf = '';
            my $n = $input->read($buf, $remaining);
            last if !defined($n) || $n <= 0;
            $remaining -= $n;
        }
''',
    r'''        my $input = $env->{'psgi.input'};
        die "missing benchmark request body\n" if !defined $input;
        while ($remaining > 0) {
            my $want = $remaining > 65_536 ? 65_536 : $remaining;
            my $buf = '';
            my $n = $input->read($buf, $want);
            die "short benchmark request body\n"
                if !defined($n) || $n <= 0;
            $remaining -= $n;
        }
''',
)

replace_once(
    "benchmarks/http/servers/linuxevent-http.pl",
    r'''our $READ_BUDGET_BYTES = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
my $payload = 'x' x $response_bytes;
''',
    r'''our $READ_BUDGET_BYTES = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
our $REQUEST_BODY_BYTES = 0 + ($ENV{BENCH_REQUEST_BODY_BYTES} // 0);
my $payload = 'x' x $response_bytes;
''',
)

replace_once(
    "benchmarks/http/servers/linuxevent-http.pl",
    r'''    sub on_request ($self, $request, $response) {
        $response->end($self->data->{payload});
        return;
    }
}

{
    package Benchmark::Web::HTTP::LinuxEvent::RequestEnd;
''',
    r'''    sub on_request ($self, $request, $response) {
        return if $main::REQUEST_BODY_BYTES > 0;
        $response->end($self->data->{payload});
        return;
    }

    sub on_request_end ($self, $request, $response) {
        return if $main::REQUEST_BODY_BYTES == 0;
        $response->end($self->data->{payload});
        return;
    }
}

{
    package Benchmark::Web::HTTP::LinuxEvent::RequestEnd;
''',
)

replace_once(
    "benchmarks/http/README.md",
    r'''```sh
perl run.pl --servers=hyperman,feersum,mojo --strict
```

### `--json=PATH`
''',
    r'''```sh
perl run.pl --servers=hyperman,feersum,mojo --strict
```

`--no-strict` explicitly restores the default skip behavior.

### `--json=PATH`
''',
)

replace_once(
    "benchmarks/http/README.md",
    r'''This variable changes only the Linux::Event adapter. Do not mix different Linux::Event modes into one published result without labeling them separately.

## Interpreting results
''',
    r'''This variable changes only the Linux::Event adapter. Do not mix different Linux::Event modes into one published result without labeling them separately.

For body-bearing benchmark requests, the `natural` adapter defers its response until `on_request_end` so the request body is fully consumed before responding. The bodyless default still measures the ordinary early `on_request -> Response->end` path.

## Files in this folder

```text
README.md
run.pl
servers/
    aiohttp-http.py
    feersum-http.pl
    go-http.go
    hyperman-http.pl
    libh2o-http.c
    linuxevent-http.pl
    mojo-http.pl
    node-http.js
    twiggy-http.pl
```

Nothing outside this directory is required unless you explicitly select an optional target that is not already installed. An uninstalled Linux::Event::Net::HTTP checkout is supplied explicitly with `BENCH_LINUXEVENT_ROOT`.

## Continuous integration

Repository CI uses small correctness workloads, including a required smoke comparison that does not select Linux::Event. Optional Perl-adapter CI may install benchmark targets temporarily to exercise their adapters; those installations are test fixtures, not Benchmark::Web dependencies.

CI throughput is not a publishable performance result.

## Interpreting results
''',
)

replace_once(
    "CONTRIBUTING.md",
    r'''A runner should detect missing competitors and skip them by default, with a strict mode when a reproducible run requires an exact target set.

## Results
''',
    r'''A runner should detect missing competitors and skip them by default, with a strict mode when a reproducible run requires an exact target set.

CI may install optional benchmark targets temporarily to exercise adapters. That does not make those targets project dependencies: do not add them to core package metadata or assume every contributor has them installed.

## Results
''',
)
