# Node.js ws adapter

Uses `WebSocketServer` from the Node.js `ws` package with permessage-deflate
disabled.

The family-level `npm install` supplies the exact `ws` dependency used by
both the shared client and this server adapter.

```sh
npm install
perl run.pl --servers=nodews --smoke --strict
```
