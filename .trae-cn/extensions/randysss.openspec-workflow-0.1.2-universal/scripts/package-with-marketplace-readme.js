#!/usr/bin/env node
/**
 * Build, extract marketplace README, run vsce package, then restore README.md.
 * So the .vsix contains only the "usage" part of README.
 */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const readmePath = path.join(rootDir, 'README.md');
const backupPath = path.join(rootDir, 'README.md.bak');

function run(cmd, opts = {}) {
  execSync(cmd, { stdio: 'inherit', cwd: rootDir, ...opts });
}

try {
  run('pnpm run build');
  run('node scripts/icon-svg-to-png.js');
  run('node scripts/extract-readme-marketplace.js');
  fs.copyFileSync(readmePath, backupPath);
  const buildReadme = path.join(rootDir, 'build', 'README.md');
  fs.copyFileSync(buildReadme, readmePath);
  run('pnpm exec vsce package --no-dependencies');
} finally {
  if (fs.existsSync(backupPath)) {
    fs.copyFileSync(backupPath, readmePath);
    fs.unlinkSync(backupPath);
  }
}
