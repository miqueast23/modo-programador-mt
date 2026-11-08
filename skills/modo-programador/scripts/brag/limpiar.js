// Quita scripts de las instantáneas: deben ser contenido inerte.
const fs = require('fs'), path = require('path');
const dir = process.argv[2];
for (const f of fs.readdirSync(dir).filter(f => f.endsWith('.html') && !f.startsWith('comp'))) {
  const p = path.join(dir, f);
  const s = fs.readFileSync(p, 'utf8').replace(/<script\b[\s\S]*?<\/script>/gi, '');
  fs.writeFileSync(p, s);
  console.log(f, (s.match(/<script/gi) || []).length);
}
