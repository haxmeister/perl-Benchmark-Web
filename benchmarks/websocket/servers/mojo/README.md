# Mojolicious WebSocket adapter

Uses a normal Mojolicious `websocket` route in a single daemon process.
Compression is not requested by the shared client.

Requires Mojolicious to be installed.

```sh
perl run.pl --servers=mojo --smoke --strict
```
