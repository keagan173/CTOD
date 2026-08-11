import { execFileSync } from 'node:child_process';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const productionRef = 'wezcuprboyvbmlnuqdoi';

function filesUnder(directory) {
  return readdirSync(directory).flatMap((name) => {
    const path = join(directory, name);
    return statSync(path).isDirectory() ? filesUnder(path) : [path];
  });
}

const javascript = [
  ...filesUnder(resolve(root, 'public')).filter((path) => path.endsWith('.js')),
  ...filesUnder(resolve(root, 'scripts')).filter((path) => path.endsWith('.mjs')),
];
for (const file of javascript) execFileSync(process.execPath, ['--check', file], { stdio: 'inherit' });

const browserFiles = filesUnder(resolve(root, 'public')).filter(
  (path) => path.endsWith('.js') || path.endsWith('.html'),
);
const coupled = browserFiles.filter((path) => readFileSync(path, 'utf8').includes(productionRef));
if (coupled.length) {
  throw new Error(`Production project ref remains embedded in browser source: ${coupled.join(', ')}`);
}

console.log(`Checked ${javascript.length} JavaScript modules; browser source is environment-neutral.`);
