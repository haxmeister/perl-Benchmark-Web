import http from 'node:http';
import { WebSocketServer } from 'ws';

const port = Number(process.env.BENCH_PORT);
if (!Number.isInteger(port) || port < 1) throw new Error('BENCH_PORT is required');

const ack = '{"ok":true}';
const server = http.createServer();
const wss = new WebSocketServer({
  server,
  path: '/application',
  perMessageDeflate: false,
  maxPayload: 32 * 1024 * 1024,
});

wss.on('connection', ws => {
  ws.on('message', (data, isBinary) => {
    if (isBinary || data.subarray(0, 6).toString() !== '{"op":') {
      ws.close(1003, 'invalid benchmark request');
      return;
    }
    ws.send(ack, { binary: false, compress: false });
  });
});

server.listen(port, '127.0.0.1');
