#!/usr/bin/env node
/**
 * Publish the current extension to Open VSX.
 * Requires OVSX_TOKEN (Personal Access Token from https://open-vsx.org/user-settings/tokens).
 * Do not commit the token; set it in the environment or in a local .env (not committed).
 *
 * Expects a .vsix file in the project root (run `pnpm run package` first).
 * Publishing a pre-packaged .vsix avoids ovsx running npm in a pnpm repo.
 */
const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const token = process.env.OVSX_TOKEN;
if (!token || token.trim() === '') {
  console.error('Error: OVSX_TOKEN must be set for publishing to Open VSX.');
  console.error('Create a token at https://open-vsx.org/user-settings/tokens');
  console.error('Then run: OVSX_TOKEN=your-token pnpm run publish:openvsx');
  process.exit(1);
}

const cwd = process.cwd();
const files = fs.readdirSync(cwd).filter((f) => f.endsWith('.vsix'));
if (files.length === 0) {
  console.error('Error: No .vsix file found. Run "pnpm run package" first.');
  process.exit(1);
}
if (files.length > 1) {
  console.error('Error: Multiple .vsix files found. Remove old builds or run "pnpm run package" to get a single .vsix.');
  process.exit(1);
}

const vsixPath = path.join(cwd, files[0]);
execSync(`pnpm exec ovsx publish "${vsixPath}"`, {
  stdio: 'inherit',
  env: { ...process.env, OVSX_PAT: token },
});
