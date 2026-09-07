from pathlib import Path

run_path = Path('benchmarks/http/run.pl')
text = run_path.read_text()

old = r'''my @summary;
say '';
say 'Median comparison';
printf "%-24s %12s %12s %12s %12s %12s\n",
    'server', 'req/s', 'p50 us', 'p95 us', 'p99 us', 'max us';
for my $name (@available) {
    my @set = grep { $_->{server} eq $name } @records;
    my $row = {
        server => $name,
        label => $server{$name}{label},
        requests_per_second => median(map { $_->{requests_per_second} } @set),
        latency_us_p50 => median(map { $_->{latency_us_p50} } @set),
        latency_us_p95 => median(map { $_->{latency_us_p95} } @set),
        latency_us_p99 => median(map { $_->{latency_us_p99} } @set),
        latency_us_max => median(map { $_->{latency_us_max} } @set),
    };
    push @summary, $row;
    printf "%-24s %12.1f %12.1f %12.1f %12.1f %12.1f\n",
        $row->{label},
        @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
}
'''

new = r'''my @summary;
for my $name (@available) {
    my @set = grep { $_->{server} eq $name } @records;
    my $row = {
        server => $name,
        label => $server{$name}{label},
        requests_per_second => median(map { $_->{requests_per_second} } @set),
        latency_us_p50 => median(map { $_->{latency_us_p50} } @set),
        latency_us_p95 => median(map { $_->{latency_us_p95} } @set),
        latency_us_p99 => median(map { $_->{latency_us_p99} } @set),
        latency_us_max => median(map { $_->{latency_us_max} } @set),
    };
    push @summary, $row;
}
print_terminal_summary(\@summary);
'''

if old not in text:
    raise SystemExit('summary block not found')
text = text.replace(old, new, 1)

marker = 'sub configure_linuxevent () {\n'
helper = r'''sub print_terminal_summary ($summary) {
    my $profile = $smoke
        ? 'SMOKE - correctness check only; do not publish throughput'
        : 'measurement';
    my $method = $request_body_bytes > 0 ? 'POST' : 'GET';
    my $availability = $strict
        ? 'strict - every requested target required'
        : 'missing targets are skipped';
    my $server_labels = join(', ', map { $server{$_}{label} } @available);
    my $skipped_labels = join(', ', map { $server{$_}{label} } @skipped);
    my $result_note = $repeats == 1
        ? 'single measured run; latency is client-visible'
        : "median of $repeats repeats; latency is client-visible";

    say '';
    say '=' x 100;
    say 'Benchmark::Web - HTTP/1.1 Cross-Server Comparison';
    say '=' x 100;
    printf "  %-25s %s\n", 'Profile:', $profile;
    printf "  %-25s %s\n", 'Servers tested:', $server_labels;
    printf "  %-25s %s\n", 'Servers skipped:', $skipped_labels if @skipped;
    printf "  %-25s %d\n", 'Measured requests/repeat:', $requests;
    printf "  %-25s %d\n", 'Warmup requests/repeat:', $warmup;
    printf "  %-25s %d\n", 'Repeats:', $repeats;
    printf "  %-25s %d persistent HTTP/1.1\n", 'Connections:', $connections;
    printf "  %-25s %d\n", 'Pipeline depth:', $pipeline;
    printf "  %-25s %s /bench, body=%d bytes\n",
        'Request:', $method, $request_body_bytes;
    printf "  %-25s HTTP 200, fixed body=%d bytes\n",
        'Response:', $response_bytes;
    printf "  %-25s %.3g seconds\n", 'Phase timeout:', $timeout;
    printf "  %-25s %s\n", 'Availability:', $availability;
    printf "  %-25s %s\n", 'Transport:', 'loopback TCP';
    printf "  %-25s %s\n", 'Client:', 'shared raw Perl client';
    printf "  %-25s %s\n", 'Server policy:',
        'one process; one application execution slot';
    if (grep { $_ eq 'linuxevent' } @available) {
        printf "  %-25s %s\n", 'Linux::Event mode:',
            ($ENV{BENCH_LINUXEVENT_MODE} // 'natural');
    }
    printf "  %-25s %s\n", 'JSON report:', $json_path
        if defined $json_path;

    say '-' x 100;
    say 'MEDIAN RESULTS';
    say '-' x 100;
    printf "%-24s %12s %12s %12s %12s %12s\n",
        'server', 'req/s', 'p50 us', 'p95 us', 'p99 us', 'max us';
    for my $row (@$summary) {
        printf "%-24s %12.1f %12.1f %12.1f %12.1f %12.1f\n",
            $row->{label},
            @{$row}{qw(requests_per_second latency_us_p50 latency_us_p95 latency_us_p99 latency_us_max)};
    }
    say '-' x 100;
    say "  $result_note";
    say '  Persistent HTTP/1.1 | loopback TCP | single-process / single-execution-slot';
    say '=' x 100;
    return;
}

'''

if marker not in text:
    raise SystemExit('configure_linuxevent marker not found')
text = text.replace(marker, helper + marker, 1)
run_path.write_text(text)

ci_path = Path('.github/workflows/ci.yml')
ci = ci_path.read_text()
old_ci = r'''          perl benchmarks/http/run.pl \
            --servers=node,go \
            --smoke \
            --strict \
            --json=/tmp/http-smoke.json
          test -s /tmp/http-smoke.json
'''
new_ci = r'''          perl benchmarks/http/run.pl \
            --servers=node,go \
            --smoke \
            --strict \
            --json=/tmp/http-smoke.json | tee /tmp/http-smoke.out
          test -s /tmp/http-smoke.json
          grep -F 'Benchmark::Web - HTTP/1.1 Cross-Server Comparison' /tmp/http-smoke.out
          grep -F 'SMOKE - correctness check only' /tmp/http-smoke.out
          grep -F 'Measured requests/repeat:' /tmp/http-smoke.out
          grep -F 'Warmup requests/repeat:' /tmp/http-smoke.out
          grep -F 'Pipeline depth:' /tmp/http-smoke.out
          grep -F 'Request:' /tmp/http-smoke.out
          grep -F 'Response:' /tmp/http-smoke.out
          grep -F 'MEDIAN RESULTS' /tmp/http-smoke.out
'''
if old_ci not in ci:
    raise SystemExit('baseline CI smoke block not found')
ci = ci.replace(old_ci, new_ci, 1)

old_body = r'''          perl benchmarks/http/run.pl \
            --servers=node,go \
            --smoke \
            --strict \
            --request-body-bytes=4096
'''
new_body = r'''          perl benchmarks/http/run.pl \
            --servers=node,go \
            --smoke \
            --strict \
            --request-body-bytes=4096 | tee /tmp/http-body-smoke.out
          grep -E 'Request: +POST /bench, body=4096 bytes' /tmp/http-body-smoke.out
'''
if old_body not in ci:
    raise SystemExit('body CI smoke block not found')
ci = ci.replace(old_body, new_body, 1)
ci_path.write_text(ci)
