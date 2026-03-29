/**
 * Workaround for Vitest + pnpm: when the IDE runs Vitest, it can resolve the
 * package to a pnpm path variant that does not exist (e.g. without _yaml@x.x.x).
 * This script creates a symlink from that missing variant to the actual
 * vitest package so `suppress-warnings.cjs` is found.
 * Run as: node scripts/link-vitest-pnpm.js
 */
const fs = require('fs');
const path = require('path');

const vitestRoot = path.dirname(require.resolve('vitest/package.json'));
const suppressPath = path.join(vitestRoot, 'suppress-warnings.cjs');
if (!fs.existsSync(suppressPath)) process.exit(0);

// vitestRoot is like .../vitest@4.0.18_..._yaml@2.8.2/node_modules/vitest
// We need .../vitest@4.0.18_... (no _yaml@...) /node_modules/vitest
const match = vitestRoot.match(/^(.+[/\\])(vitest@[^/\\]+)(_yaml@[^/\\]+)([/\\]node_modules[/\\]vitest)$/);
if (!match) process.exit(0);

const [, base, pkgName, yamlSuffix, rest] = match;
const shortVitestDir = base + pkgName + rest;
const shortSuppress = path.join(shortVitestDir, 'suppress-warnings.cjs');

if (shortVitestDir === vitestRoot || fs.existsSync(shortSuppress)) process.exit(0);

try {
  const parent = path.dirname(shortVitestDir);
  fs.mkdirSync(parent, { recursive: true });
  fs.symlinkSync(vitestRoot, shortVitestDir, 'dir');
} catch (e) {
  // Ignore: may not have write to .pnpm or already linked
}
