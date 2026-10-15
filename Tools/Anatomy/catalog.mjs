import { readFileSync, readdirSync, mkdirSync } from 'node:fs';
import { resolve, join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';

export const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const source = name => readFileSync(join(root, name), 'utf8');
const number = (text, pattern, label) => {
  const value = text.match(pattern)?.[1];
  if (!value) throw new Error(`Source extraction failed: ${label}`);
  return Number(value);
};

export function readCatalog({ images = false } = {}) {
  const paintings = [...source('Gallery Glow/PaintingData.swift').matchAll(/Painting\(title: "([^"]+)", year: (\d+), artistName: "([^"]+)", imageName: "([^"]+)", description: "([^"]+)"(?:, forceFullScreen: (true|false))?\)/g)].map(([, title, year, artist, imageName, description, full]) => ({ id: `painting/${imageName}`, kind: 'painting', title, year: Number(year), artist, imageName, description, directorsCut: full === 'true' }));
  const paletteSource = source('Gallery Glow/GradientPalette.swift');
  const paletteNames = [...paletteSource.matchAll(/^    case \w+ = "([^"]+)"/gm)].map(match => match[1]);
  const rgb = [...paletteSource.matchAll(/Color\(red: ([\d.]+), green: ([\d.]+), blue: ([\d.]+)\)/g)].map(([, ...values]) => '#' + values.map(value => Math.round(Number(value) * 255).toString(16).padStart(2, '0')).join(''));
  const palettes = paletteNames.map((title, i) => ({ id: `gradient/${title}`, kind: 'gradient', title, colors: rgb.slice(i * 4, i * 4 + 4) }));
  if (!paintings.length || rgb.length !== palettes.length * 4) throw new Error('Catalog format changed: update the anatomy extractor.');
  const loader = source('Gallery Glow/ImageExtensions.swift');
  const gradients = source('Gallery Glow/GradientScreensaverView.swift');
  const limits = {
    recents: number(source('Gallery Glow/RecentlyUsedManager.swift'), /maxRecentItems = (\d+)/, 'recents'),
    shelfRecents: number(source('Gallery Shelf/ContentProvider.swift'), /recentItems.prefix\((\d+)\)/, 'shelf recents'),
    decodes: number(loader, /maxConcurrentOperationCount = (\d+)/, 'decodes'),
    cacheMiB: number(loader, /images.totalCostLimit = (\d+) \* 1024 \* 1024/, 'image cache'),
    previewMiB: number(loader, /previews.totalCostLimit = (\d+) \* 1024 \* 1024/, 'preview cache'),
    transitionSeconds: number(gradients, /transitionDuration: Double = ([\d.]+)/, 'transition'),
    colorIntervalSeconds: number(gradients, /colorChangeInterval: Double = ([\d.]+)/, 'interval'),
  };
  if (images) {
    const output = join(root, 'artifacts/anatomy/thumbs');
    mkdirSync(output, { recursive: true });
    paintings.forEach((painting, i) => {
      const folder = join(root, 'Gallery Glow/Assets.xcassets', painting.imageName + '.imageset');
      const assets = JSON.parse(readFileSync(join(folder, 'Contents.json'), 'utf8'));
      const filename = assets.images.find(image => image.filename)?.filename;
      if (!filename || !readdirSync(folder).includes(filename)) throw new Error(`Missing artwork: ${painting.imageName}`);
      const target = join(output, `${i}.jpg`);
      execFileSync('sips', ['-s', 'format', 'jpeg', '-s', 'formatOptions', '55', '-Z', '320', join(folder, filename), '--out', target], { stdio: 'pipe' });
      painting.image = 'data:image/jpeg;base64,' + readFileSync(target).toString('base64');
    });
  }
  return { paintings, palettes, limits };
}
