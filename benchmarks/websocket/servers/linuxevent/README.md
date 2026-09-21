# Linux::Event::WebSocket adapter

Uses the normal `Linux::Event::WebSocket::Server` public API with one
`on_message` callback and one process.

The launcher checks, in order, for a sibling
`perl-Linux-Event-WebSocket` checkout with built `blib` directories and then
for an installed distribution.

From `benchmarks/websocket/`:

```sh
perl run.pl --servers=linuxevent --smoke --strict
```
