import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const out = path.join(root, 'out');
fs.mkdirSync(out, { recursive: true });

const types = {
  '.html': 'text/html; charset=utf-8',
  '.woff2': 'font/woff2',
  '.webm': 'video/webm',
  '.mp4': 'video/mp4',
  '.png': 'image/png',
};

http
  .createServer((q, r) => {
    const u = new URL(q.url, 'http://localhost');
    if (q.method === 'POST' && u.pathname === '/upload') {
      const name = path.basename(u.searchParams.get('name') || 'shakti-promo.webm');
      if (!/^[\w.-]+\.(webm|mp4)$/.test(name)) return r.writeHead(400).end('bad name');
      const ws = fs.createWriteStream(path.join(out, name));
      q.pipe(ws);
      ws.on('finish', () => r.writeHead(200).end('ok'));
      ws.on('error', () => r.writeHead(500).end('error'));
      return;
    }
    let p = decodeURIComponent(u.pathname);
    if (p === '/') p = '/shakti-promo.html';
    const f = path.normalize(path.join(root, p));
    if (!f.startsWith(root + path.sep) || !types[path.extname(f)]) return r.writeHead(404).end('not found');
    fs.readFile(f, (e, d) => {
      if (e) return r.writeHead(404).end('not found');
      r.writeHead(200, { 'Content-Type': types[path.extname(f)] }).end(d);
    });
  })
  .listen(4010, '127.0.0.1', () => console.log('up 4010'));
