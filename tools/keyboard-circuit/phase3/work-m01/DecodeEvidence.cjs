const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const [input, output] = process.argv.slice(2);
const root = path.resolve(__dirname, '../../../..');
for (const name of [input, output]) {
  const resolved = path.resolve(root, name);
  const relative = path.relative(root, resolved);
  if (!relative || relative.startsWith('..') || path.isAbsolute(relative)) throw Error('Evidence path outside workspace');
}
const raw = zlib.zstdDecompressSync(Buffer.from(fs.readFileSync(path.resolve(root, input), 'utf8'), 'base64'));
fs.writeFileSync(path.resolve(root, output), raw);
console.log(JSON.stringify({output, bytes: raw.length, sha256: crypto.createHash('sha256').update(raw).digest('hex')}));
