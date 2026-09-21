# Go gorilla/websocket adapter

Uses the public `gorilla/websocket` Upgrader and Conn APIs. The launcher builds
a temporary binary from the pinned Go module and runs it with `GOMAXPROCS=1`.

Requires the Go toolchain and network access the first time the module is
downloaded.

```sh
perl run.pl --servers=gorilla --smoke --strict
```
