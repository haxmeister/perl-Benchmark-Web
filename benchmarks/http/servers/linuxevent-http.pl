#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Loop;
use Linux::Event::Net::HTTP::Connection;
use Linux::Event::Net::HTTP::Server;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $mode = $ENV{BENCH_LINUXEVENT_MODE} // 'natural';
our $READ_BUDGET_BYTES = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
my $payload = 'x' x $response_bytes;

{
    package Benchmark::Web::HTTP::LinuxEvent::Natural;
    use parent 'Linux::Event::Net::HTTP::Connection';

    sub stream_options ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->end($self->data->{payload});
        return;
    }
}

{
    package Benchmark::Web::HTTP::LinuxEvent::RequestEnd;
    use parent 'Linux::Event::Net::HTTP::Connection';

    sub stream_options ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->end($self->data->{payload});
        return;
    }
}

{
    package Benchmark::Web::HTTP::LinuxEvent::FastFinal;
    use parent 'Linux::Event::Net::HTTP::Connection';

    sub stream_options ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request_final ($self, $request) {
        return $self->data->{payload};
    }

    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->end($self->data->{payload});
        return;
    }
}

my $connection_class = $mode eq 'natural'
    ? 'Benchmark::Web::HTTP::LinuxEvent::Natural'
    : $mode eq 'request-end'
        ? 'Benchmark::Web::HTTP::LinuxEvent::RequestEnd'
        : $mode eq 'fast-final'
            ? 'Benchmark::Web::HTTP::LinuxEvent::FastFinal'
            : die "unknown BENCH_LINUXEVENT_MODE: $mode\n";

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::Net::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0 + $port,
    data             => { payload => $payload },
    connection_class => $connection_class,
);

$loop->run;
