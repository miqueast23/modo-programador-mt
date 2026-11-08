// Renderiza comp.html fotograma a fotograma (cada fotograma = setT(t)).
// Uso: node render.js <dirComp> <dirSalida> stills 1.5,4.8,...   |   node render.js <dirComp> <dirSalida> frames 21 30
const path = require('path'), http = require('http'), fs = require('fs');
const { chromium } = require(path.join(process.env.APPDATA, 'npm/node_modules/playwright'));
const [root, out, modo, a1, a2] = process.argv.slice(2);
fs.mkdirSync(out, { recursive: true });
const tipos = { '.html': 'text/html; charset=utf-8', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png' };
const srv = http.createServer((q, r) => {
  const p = path.join(root, decodeURIComponent(q.url.split('?')[0]));
  if (!p.startsWith(root) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { 'Content-Type': tipos[path.extname(p)] || 'application/octet-stream' }); fs.createReadStream(p).pipe(r);
}).listen(8978);
(async () => {
  const b = await chromium.launch();
  const ctx = await b.newContext({ viewport: { width: 1920, height: 1080 } });
  await ctx.route('**/*', r => { const u = r.request().url();
    return (u.startsWith('http://localhost:8978') || u.includes('fonts.g')) ? r.continue() : r.abort(); });
  const pg = await ctx.newPage();
  pg.on('pageerror', e => console.log('pageerror:', e.message));
  await pg.goto('http://localhost:8978/comp.html', { waitUntil: 'load' });
  console.log('listo', JSON.stringify(await pg.evaluate(() => listo())));
  const toma = async (t, f) => { await pg.evaluate(t => setT(t), t); await pg.screenshot({ path: f, type: f.endsWith('.jpg') ? 'jpeg' : 'png', quality: f.endsWith('.jpg') ? 95 : undefined }); };
  if (modo === 'stills') for (const t of a1.split(',').map(Number)) await toma(t, path.join(out, `still-${t.toFixed(2)}.png`));
  else { const dur = +a1, fps = +a2, n = Math.round(dur * fps);
    for (let i = 0; i < n; i++) { await toma(i / fps, path.join(out, String(i).padStart(5, '0') + '.jpg')); if (i % 60 === 0) console.log('frame', i, '/', n); } }
  await b.close(); srv.close(); console.log('fin');
})().catch(e => { console.error(e); process.exit(1); });
