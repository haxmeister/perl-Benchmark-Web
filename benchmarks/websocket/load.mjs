import WebSocket from 'ws';

function args(argv) {
  const out = {};
  for (let i = 2; i < argv.length; ++i) {
    if (!argv[i].startsWith('--') || i + 1 >= argv.length) {
      throw new Error(`invalid argument: ${argv[i]}`);
    }
    out[argv[i].slice(2)] = argv[++i];
  }
  return out;
}

const o = args(process.argv);
const label = o.label ?? 'server';
const port = Number(o.port);
const bytes = Number(o.bytes ?? 256);
const clients = Number(o.connections ?? 100);
const windowSize = Number(o.window ?? 4);
const warmup = Number(o.warmup ?? 0.75);
const seconds = Number(o.seconds ?? 3);

const prefix = '{"op":"message","room":"bench","body":"';
const suffix = '","seq":12345}';
if (!Number.isInteger(port) || port < 1) throw new Error('invalid --port');
if (!Number.isInteger(bytes) || bytes < prefix.length + suffix.length) throw new Error('invalid --bytes');
if (!Number.isInteger(clients) || clients < 1) throw new Error('invalid --connections');
if (!Number.isInteger(windowSize) || windowSize < 1) throw new Error('invalid --window');
if (!(warmup >= 0) || !(seconds > 0)) throw new Error('invalid duration');

const payload = prefix + 'x'.repeat(bytes - prefix.length - suffix.length) + suffix;
const ack = '{"ok":true}';
const sockets = [];
let opened = 0;
let count = 0;
let measuring = false;
let stopped = false;
let finished = false;
let startNs = 0n;
let setupTimer;

function fail(message) {
  if (finished) return;
  finished = true;
  stopped = true;
  for (const ws of sockets) {
    try { ws.terminate(); } catch {}
  }
  console.error(message);
  process.exitCode = 1;
}

function sendOne(ws) {
  if (!stopped) ws.send(payload, { binary: false, compress: false });
}

function finish() {
  if (finished) return;
  finished = true;
  stopped = true;
  const elapsed = Number(process.hrtime.bigint() - startNs) / 1e9;
  const rate = count / elapsed;
  for (const ws of sockets) {
    try { ws.terminate(); } catch {}
  }
  console.log([label, bytes, clients, windowSize, count, elapsed.toFixed(6), rate.toFixed(0)].join(','));
}

function begin() {
  for (const ws of sockets) {
    for (let i = 0; i < windowSize; ++i) sendOne(ws);
  }
  setTimeout(() => {
    count = 0;
    measuring = true;
    startNs = process.hrtime.bigint();
    setTimeout(finish, seconds * 1000);
  }, warmup * 1000);
}

for (let i = 0; i < clients; ++i) {
  const ws = new WebSocket(`ws://127.0.0.1:${port}/application`, {
    perMessageDeflate: false,
    maxPayload: 32 * 1024 * 1024,
  });
  sockets.push(ws);

  ws.on('open', () => {
    if (++opened === clients) {
      clearTimeout(setupTimer);
      begin();
    }
  });

  ws.on('message', (data, isBinary) => {
    if (stopped) return;
    if (isBinary || data.toString() !== ack) {
      fail('application acknowledgement mismatch');
      return;
    }
    if (measuring) ++count;
    sendOne(ws);
  });

  ws.on('error', e => fail(`WebSocket load-generator error: ${e.message}`));
  ws.on('close', () => {
    if (!stopped) fail('server closed benchmark connection early');
  });
}

setupTimer = setTimeout(() => {
  if (!finished && opened !== clients) fail(`connection setup timed out: opened ${opened}/${clients}`);
}, 15_000);
