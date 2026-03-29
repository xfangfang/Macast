#!/usr/bin/env node
/**
 * Converts resources/icon.svg to resources/icon.png at 128x128 (VS Code marketplace icon).
 * SVG is scaled to fit inside 128x128 and centered; excess is transparent (width or height letterbox).
 * Run: node scripts/icon-svg-to-png.js
 * Or: make icon-png
 */

const { Resvg } = require('@resvg/resvg-js');
const sharp = require('sharp');
const { readFileSync, writeFileSync } = require('fs');
const path = require('path');

const SIZE = 128;
const root = path.resolve(__dirname, '..');
const src = path.join(root, 'resources', 'icon.svg');
const out = path.join(root, 'resources', 'icon.png');

const svg = readFileSync(src);
const resvg0 = new Resvg(svg);
const svgW = resvg0.width;
const svgH = resvg0.height;

// Scale to fit inside SIZE x SIZE; one dimension will be SIZE, the other <= SIZE
const fitTo =
  svgW >= svgH
    ? { mode: 'width', value: SIZE }   // wide or square -> fit to width, height has padding
    : { mode: 'height', value: SIZE };  // tall -> fit to height, width has padding

const resvg = new Resvg(svg, { fitTo });
const pngData = resvg.render();
const pngBuffer = pngData.asPng();
const w = pngData.width;
const h = pngData.height;

const left = Math.floor((SIZE - w) / 2);
const right = SIZE - w - left;
const top = Math.floor((SIZE - h) / 2);
const bottom = SIZE - h - top;

async function main() {
  const outBuffer = await sharp(pngBuffer)
    .ensureAlpha()
    .extend({
      top,
      bottom,
      left,
      right,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();

  writeFileSync(out, outBuffer);
  console.log(`Wrote ${out} (${SIZE}x${SIZE}, content ${w}x${h} centered)`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
