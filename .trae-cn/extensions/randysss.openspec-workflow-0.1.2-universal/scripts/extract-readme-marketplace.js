#!/usr/bin/env node
/**
 * Extract the "usage" part of README.md (content before the first line that is only `---`).
 * Writes to build/README.md for packaging or for testing (make readme-marketplace).
 */
const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const readmePath = path.join(rootDir, 'README.md');
const outPath = path.join(rootDir, 'build', 'README.md');

const content = fs.readFileSync(readmePath, 'utf8');
const lines = content.split(/\r?\n/);

let endIndex = lines.length;
for (let i = 0; i < lines.length; i++) {
  if (/^\s*---\s*$/.test(lines[i])) {
    endIndex = i;
    break;
  }
}

const usagePart = lines.slice(0, endIndex).join('\n');
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, usagePart, 'utf8');
console.log('Wrote build/README.md (usage part only, %d lines)', endIndex);
