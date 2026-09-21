use strict;
use warnings;

my $response_bytes = 0 + ($ENV{BENCH_RESPONSE_BYTES} // 32);
my $body = 'x' x $response_bytes;

my $app = sub {
    my ($env) = @_;

    my $remaining = 0 + ($env->{CONTENT_LENGTH} // 0);
    my $input = $env->{'psgi.input'};
    while ($remaining > 0) {
        my $want = $remaining > 65_536 ? 65_536 : $remaining;
        my $chunk = '';
        my $read = $input->read($chunk, $want);
        die "benchmark request body ended early\n"
            if !defined($read) || $read <= 0;
        $remaining -= $read;
    }

    return [
        200,
        [
            'Content-Type' => 'application/octet-stream',
            'Content-Length' => length($body),
        ],
        [$body],
    ];
};

{
    no warnings 'void';
    $app;
}
