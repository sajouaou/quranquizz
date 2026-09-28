// Recreates node_modules/.bin as small wrapper scripts instead of symlinks.
// Used when the project lives on a filesystem without symlink support
// (NTFS/exFAT/FAT partitions, some shared folders), after `npm ci --no-bin-links`.
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', 'node_modules');
const binDir = path.join(root, '.bin');
fs.mkdirSync(binDir, { recursive: true });

const packages = [];
for (const entry of fs.readdirSync(root)) {
  if (entry.startsWith('.')) continue;
  if (entry.startsWith('@')) {
    for (const sub of fs.readdirSync(path.join(root, entry))) packages.push(path.join(entry, sub));
  } else {
    packages.push(entry);
  }
}

let count = 0;
for (const name of packages) {
  let pkg;
  try {
    pkg = JSON.parse(fs.readFileSync(path.join(root, name, 'package.json'), 'utf8'));
  } catch {
    continue;
  }
  if (!pkg.bin) continue;
  const bins = typeof pkg.bin === 'string' ? { [path.basename(pkg.name)]: pkg.bin } : pkg.bin;
  for (const [bin, target] of Object.entries(bins)) {
    const rel = path.posix.join('..', name.split(path.sep).join('/'), target);
    const file = path.join(binDir, bin);
    fs.writeFileSync(file, `#!/bin/sh\nexec node "$(dirname "$0")/${rel}" "$@"\n`);
    fs.writeFileSync(`${file}.cmd`, `@node "%~dp0\\${rel.split('/').join('\\')}" %*\r\n`);
    try { fs.chmodSync(file, 0o755); } catch { /* filesystem without permissions */ }
    count++;
  }
}
console.log(`Created ${count} command wrappers in node_modules/.bin`);
