import { readFileSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { readCatalog, root } from './catalog.mjs';
import { buildGeometry } from './geometry.mjs';
import { ISO_CSS } from './vendor/iso-kit.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const catalog = readCatalog({ images: true });
const geometry = buildGeometry(catalog);
const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
const sourceURL = path => `https://github.com/yssf-c/Gallery-Glow/blob/${commit}/${path.split('/').map(encodeURIComponent).join('/')}`;
const L = catalog.limits;
const sections = [
  { id: 'catalog', name: 'Collection', title: 'The local collection', stat: `${catalog.paintings.length} paintings · ${catalog.palettes.length} palettes`,
    text: 'The magazine is the bundled collection. PaintingData builds artists and paintings; GradientPalette supplies five sets of four colors. Today’s free artwork is selected from Director’s Cut using the local calendar day of the year.',
    detail: `daily index = (day of year − 1) % ${catalog.paintings.filter(p => p.directorsCut).length} · resets each January 1`,
    files: ['Gallery Glow/PaintingData.swift', 'Gallery Glow/GradientPalette.swift', 'Gallery Glow/Models.swift'] },
  { id: 'session', name: 'Selection', title: 'Every entrance, one owner', stat: '1 presentation owner',
    text: 'The carrier is GallerySession. ContentView, ArtistView, recent cards, and galleryglow:// links all hand it a painting or gradient. ContentView presents one full-screen cover; changing the selection replaces its content instead of stacking another cover.',
    detail: 'Gallery_GlowApp → ContentView → GallerySession.present / open → ScreensaverPresentation',
    files: ['Gallery Glow/GallerySession.swift', 'Gallery Glow/ContentView.swift', 'Gallery Glow/ArtistView.swift', 'Gallery Glow/Gallery_GlowApp.swift'] },
  { id: 'access', name: 'Access', title: 'A shutter with two keys', stat: 'Daily artwork or lifetime',
    text: 'The shutter admits today’s painting for free. All other paintings and every gradient require a lifetime entitlement. A locked request waits in pendingSelection while PaywallView appears. PurchaseManager reads verified StoreKit entitlements; after an unlock, reconciliation resumes the waiting selection.',
    detail: 'An admitted free viewing survives midnight. Reopening checks the new day. Legacy lifetime purchases remain recognized.',
    files: ['Gallery Glow/GallerySession.swift', 'Gallery Glow/PurchaseManager.swift', 'Gallery Glow/PaywallView.swift'] },
  { id: 'display', name: 'Display', title: 'Two ways to fill the room', stat: 'Artwork / 4 × 4 mesh',
    text: 'One viewing surface has two native renderers. ScreensaverView displays a painting, using fill for Director’s Cut works or near-16:9 images and a fitted frame otherwise. GradientScreensaverView animates a 4 × 4 MeshGradient. Pause, backgrounding, and Reduce Motion stop gradient animation.',
    detail: `${L.colorIntervalSeconds}s palette hold + ${L.transitionSeconds}s transition · controls hide after 5s · idle timer disabled only during active viewing`,
    files: ['Gallery Glow/ScreensaverView.swift', 'Gallery Glow/GradientScreensaverView.swift', 'Gallery Glow/ContentView.swift'] },
  { id: 'images', name: 'Images', title: 'Decode only what is needed', stat: `${L.decodes} concurrent decodes`,
    text: 'The cartridges under the screen represent the image pipeline. PaintingImage creates requests from size, scale, and fit/fill mode. PaintingImageLoader coalesces identical requests and limits parallel decoding. ImageCache keeps display-sized images and small previews in separate caches.',
    detail: `${L.cacheMiB} MiB image cache budget + ${L.previewMiB} MiB preview budget · requests round up to 64 px buckets · memory warnings clear both`,
    files: ['Gallery Glow/ImageExtensions.swift', 'Gallery Glow/ContentView.swift'] },
  { id: 'recents', name: 'Memory', title: 'Remember admitted selections', stat: `${L.recents} saved items`,
    text: 'The index rack is RecentlyUsedManager. An admitted selection moves to the front, duplicates are removed, and the list is capped at ten. A shared Codable schema is stored as JSON in App Group UserDefaults so the app and extension read the same history. A locked request is not recorded.',
    detail: 'group.com.galleryglow.shared · recentlyUsedItems · topShelfContentDidChange()',
    files: ['Gallery Glow/RecentlyUsedManager.swift', 'Gallery Glow/GallerySession.swift'] },
  { id: 'shelf', name: 'Top Shelf', title: 'The gallery outside the app', stat: `Up to ${L.shelfRecents} recent cards`,
    text: 'The raised shelf is a separate TVServices extension. ContentProvider builds Painting of the Day, up to eight valid recent entries, and Director’s Cut excluding today. Tapping a card returns through a galleryglow:// link and the same GallerySession access gate. This rack represents the recent section.',
    detail: '888 × 500 bundled JPEG previews · no live image rendering in the extension · TopShelfManager refreshes on a new day or design version',
    files: ['Gallery Shelf/ContentProvider.swift', 'Gallery Glow/TopShelfManager.swift', 'Tools/GenerateTopShelfImages.swift'] },
].map(section => ({ ...section, sources: section.files.map(path => ({ label: path.split('/').at(-1), url: sourceURL(path) })) }));

const esc = value => String(value).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('"', '&quot;');
const controls = `<section class="workbench" aria-label="Try the access flow"><div class="control-heading"><span class="eyebrow">Try the mechanism</span><small id="calendar-label"></small></div><div class="controls"><div class="picker"><label for="selection">Send a selection to the viewing gate</label><select id="selection"><optgroup label="Artwork">${catalog.paintings.map(p => `<option value="${esc(p.id)}">${esc(p.title)}</option>`).join('')}</optgroup><optgroup label="Ambient gradients">${catalog.palettes.map(p => `<option value="${esc(p.id)}">${p.title}</option>`).join('')}</optgroup></select></div><button id="lifetime" class="access-button" type="button" aria-pressed="false"><span class="switch-track" aria-hidden="true"><span class="switch-thumb"></span></span>Lifetime unlock</button></div><div class="minor-controls"><button id="today" type="button">View today’s artwork</button><button id="next-day" type="button">Next day →</button><span class="spacer"></span><button id="tour" type="button" aria-pressed="true">Pause tour</button><button id="reset" type="button">Reset</button></div><p class="demo-status" id="demo-status" role="status" aria-live="polite"></p></section>`;
const body = `<main class="anatomy"><figure class="iso-figure"><div class="iso-plate"><div class="plate-header"><span>FIG. 01 / PROJECT ANATOMY</span><strong>Gallery Glow</strong></div><div class="iso-stage" tabindex="0" role="group" aria-label="Interactive slide-viewing bench. Use left and right arrow keys to inspect systems; Enter toggles the guided tour.">${geometry.svg}</div><div class="plate-footer"><span>Touch a part to trace the code</span><span data-readout>Opening today’s artwork</span></div></div><figcaption class="caption"><p>A collection becomes a selection, passes the access gate, and lights the screen. Recent history carries it back to Apple TV’s Top Shelf.</p><span>SwiftUI · tvOS 18+</span></figcaption></figure>${controls}<nav class="system-nav" aria-label="Explore the seven systems">${sections.map((section, i) => `<button type="button" data-inspect="${section.id}" aria-pressed="${i === 0}"><span class="number">0${i + 1}</span>${section.name}</button>`).join('')}</nav><section class="inspector" aria-label="Selected system"><div class="inspector-head"><h1 id="system-title">${sections[0].title}</h1><span class="stat" id="system-stat">${sections[0].stat}</span></div><p id="system-description">${sections[0].text}</p><div class="source-links" id="source-links"></div><div class="detail-note" id="system-detail">${sections[0].detail}</div></section><details><summary>What this figure models</summary><p>This is a mechanical explanation of the source code. Controls simulate selection, access, daily rollover, and recent history locally. They do not make purchases or run the native app. Colored screen content is artwork or a palette preview; the gradient preview is not a reproduction of SwiftUI’s mesh animation.</p><p>The ${geometry.partCount} physical parts are illustrative. Catalog counts and limits are extracted from the Swift files at build time. Cache sizes are configured budgets, not live usage. Top Shelf also has featured and Director’s Cut sections beyond the eight recent mounts shown here.</p><p>Sources: checkout <code>${commit.slice(0, 10)}</code>. Core behavioral tests live in <code>Gallery GlowTests/CatalogAndLifecycleTests.swift</code>, <code>PurchaseFlowTests.swift</code>, and <code>PerformanceAndStateTests.swift</code>.</p></details><footer class="bottom"><span>On-device catalog · StoreKit access · App Group history</span><button id="appearance" type="button">Switch appearance</button></footer><noscript><p>Enable JavaScript to operate the bench. The illustration and collection description remain available without it.</p></noscript></main>`;
const css = readFileSync(join(here, 'styles.css'), 'utf8');
const model = readFileSync(join(here, 'model.mjs'), 'utf8').replace(/^export /gm, '');
const live = readFileSync(join(here, 'live.js'), 'utf8');
for (const theme of ['dark', 'light']) {
  const html = `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="color-scheme" content="${theme}"><title>Gallery Glow — Project anatomy</title><style>${ISO_CSS}\n${css}</style></head><body class="iso" data-theme="${theme}">${body}<script type="module">const CATALOG=${JSON.stringify(catalog)}; const SECTIONS=${JSON.stringify(sections)}; const PROJECTION=${JSON.stringify(geometry.P)};\n${model}\n${live.replace(/<\/(script)/gi, '<\\/$1')}</script></body></html>`;
  const path = join(root, 'docs', theme === 'light' ? 'anatomy-light.html' : 'anatomy.html');
  writeFileSync(path, html);
  console.log(`wrote ${path} (${Math.round(Buffer.byteLength(html) / 1024)} KiB, ${geometry.partCount} solids)`);
}
