import * as k from './vendor/iso-kit.mjs';
import * as A from './vendor/audit.mjs';

export function buildGeometry(catalog) {
  const width = 880, height = 490;
  const base = { x: -174, y: -85, w: 344, d: 178, r: 7 };
  const P = k.fitProjection([...k.boxCorners(base, -18, 0), [-12, -55, 126], [118, -55, 126], [165, -70, 75]], width, height, { pad: 62, azimuth: 48, elevation: 34 });
  const R = A.recorder(P);
  const at = point => k.iso(point, P);
  const line = (path, tone = 'faint', extra = {}) => k.lineSvg(path, { tone, ...extra });
  const dots = (points, tone = 'mid', size = .5) => k.dotsSvg(points.map(at), { tone, size });
  const plan = (x, y, w, d, r = .7) => ({ x, y, w, d, r });
  const items = [];
  const shifts = { admission: [0, 0, 28], carrier: [55, 0, 0] };
  function slab(name, group, p, z, h, { tone = 'mid', bevel = .5, detail = '', inner = '', move, id } = {}) {
    const svg = k.solidSvg(k.slabOf(p, z, h, P, 5, bevel), { tone, crease: 'lo', inner }) + detail;
    const part = R.put({ name, piece: move || group, group, id,
      at: [p.x + p.w / 2, p.y + p.d / 2, z + h / 2],
      move: shifts[move] || [0, 0, 0], svg,
      shapes: [R.solid(A.slab(p, z, h, { name, ground: name.startsWith('stand.foot') }, 5))] });
    items.push(part);
    return part;
  }
  function screws(p, z, inset = 3) {
    const corners = k.corners(p, inset);
    return line(corners.map(([x, y]) => k.ring(x, y, 1.35, z, P, 14)).join(''), 'lo') + dots(corners.map(([x, y]) => [x, y, z]), 'mid', .45);
  }
  function inset(p, z, gap = 2) { return line(k.planOutline(k.insetPlan(p, gap), z, P, 5)); }
  function faceRect(x, y, z, w, h, tone = 'lo') {
    return line([k.segment([x, y, z], [x + w, y, z], P), k.segment([x + w, y, z], [x + w, y, z - h], P), k.segment([x + w, y, z - h], [x, y, z - h], P), k.segment([x, y, z - h], [x, y, z], P)].join(''), tone);
  }

  // Each foot lands flush on the underside of the deck.
  for (const [i, [x, y]] of k.corners(base, 20).entries()) {
    slab(`stand.foot${i}`, 'base', plan(x - 7, y - 7, 14, 14, 3), -18, 6, { tone: 'lo' });
  }
  slab('stand.deck', 'base', base, -12, 12, { tone: 'lo', bevel: 1.5,
    inner: line(k.sideSeam(base, -5, P, 5)), detail: inset(base, 0, 5) + screws(base, 0, 10) });
  const ruler = plan(-155, 74, 219, 6, 1);
  const ticks = k.topTicks(-150, 59, 5, 5, 74, .7, [2, 4], P);
  slab('stand.ruler', 'base', ruler, 0, .7, { tone: 'lo', bevel: 0,
    detail: line(ticks.minor, 'lo') + line(ticks.major, 'mid') });
  const label = plan(89, 70, 53, 12, 1.5);
  slab('stand.label', 'base', label, 0, .7, { tone: 'lo', bevel: 0,
    detail: inset(label, .7, 1.5) + k.faceTextSvg(k.topMatrix([115.5, 78], .7, P), 'GALLERY GLOW', { size: 3, anchor: 'middle', tone: 'mid' }) });

  // Open nine-slide magazine: slots and faces, not an abstract layer stack.
  const cassette = plan(-158, -65, 58, 65, 2);
  slab('catalog.floor', 'catalog', cassette, 0, 6, { detail: screws(cassette, 6) });
  for (const x of [-158, -104]) slab(`catalog.wall${x}`, 'catalog', plan(x, -65, 4, 65, 1), 6, 14, { detail: line(k.sideSeam(plan(x, -65, 4, 65, 1), 12, P, 5)) });
  catalog.paintings.forEach((painting, i) => {
    const y = -59 + i * 6;
    slab(`catalog.slide${i}`, 'catalog', plan(-153, y, 48, 1.7, .3), 6, 37, {
      tone: 'hi', bevel: .25, detail: faceRect(-148, y + 1.7, 37, 38, 23) + faceRect(-143, y + 1.7, 33, 28, 15, 'faint'),
      id: `catalog-slide-${i}`,
    });
  });
  const paletteTray = plan(-158, 16, 58, 27, 2);
  slab('catalog.palette-tray', 'catalog', paletteTray, 0, 4, { detail: screws(paletteTray, 4) });
  catalog.palettes.forEach((palette, i) => {
    const p = plan(-153 + i * 10, 20, 8, 19, .8);
    slab(`catalog.palette${i}`, 'catalog', p, 4, 2, { detail: inset(p, 6, 1.5) });
  });

  // The selection carrier runs on two true rails. The shutter clears it first.
  for (const y of [-11, 20]) {
    const p = plan(-89, y, 104, 3, .5);
    slab(`session.rail${y}`, 'session', p, 0, 5, { detail: line(k.lineOnTop([-89, y + 1.5], [15, y + 1.5], 5, P), 'lo') });
  }
  for (const x of [-93, 15]) {
    const p = plan(x, -14, 4, 40, .6);
    slab(`session.stop${x}`, 'session', p, 0, 6, { detail: screws(p, 6, 1.5) });
  }
  for (const y of [-11, 20]) slab(`session.bearing${y}`, 'session', plan(-80, y, 22, 3, .4), 5, 2, { move: 'carrier' });
  const carrier = plan(-83, -11, 29, 34, 1.3);
  slab('session.carrier', 'session', carrier, 7, 3, { move: 'carrier', tone: 'hi', detail: screws(carrier, 10, 2.5) });
  const selectedSlide = plan(-79, -6, 21, 23, .8);
  slab('session.selected-slide', 'session', selectedSlide, 10, 1.3, { move: 'carrier', tone: 'hi', detail: inset(selectedSlide, 11.3, 3) });
  for (const y of [-23, 29]) {
    const p = plan(-49, y, 10, 7, .8);
    slab(`access.mount${y}`, 'access', p, 0, 4, { detail: screws(p, 4, 1.7) });
    slab(`access.guide${y}`, 'access', plan(-47, y + 1.5, 6, 4, .5), 4, 56, { detail: line(k.sideSeam(plan(-47, y + 1.5, 6, 4, .5), 52, P, 5)) });
  }
  const bridge = plan(-48, -21.5, 8, 56, .6);
  slab('access.crosshead', 'access', bridge, 60, 4, { detail: screws(bridge, 64, 2) });
  const blade = plan(-45, -17.5, 2, 48, .2);
  slab('access.shutter', 'access', blade, 6, 22, { move: 'admission', tone: 'hi', bevel: .2,
    inner: line(k.sideSeam(blade, 13, P, 5), 'lo') });
  slab('access.grip', 'access', plan(-46, 2, 4, 9, .6), 28, 3, { move: 'admission', detail: inset(plan(-46, 2, 4, 9, .6), 31, 1) });

  // An upright 16:9 viewing window with two hidden-image cache cartridges below.
  for (const x of [0, 94]) {
    const p = plan(x, -63, 20, 26, 2);
    slab(`display.shoe${x}`, 'display', p, 0, 3, { detail: screws(p, 3) });
    slab(`display.upright${x}`, 'display', plan(x + 6, -56, 8, 10, 1), 3, 28);
  }
  const screenCase = plan(-8, -58, 130, 9, 2);
  slab('display.case', 'display', screenCase, 31, 85, { tone: 'hi', bevel: 1,
    inner: line(k.sideSeam(screenCase, 111, P, 5)),
    detail: Array.from({ length: 13 }, (_, i) => line(k.planOutline(plan(2 + i * 8, -55.5, 4, 3, 1), 116, P, 4), 'lo')).join('') });
  slab('display.bezel-left', 'display', plan(-8, -49, 5, 3, .5), 31, 85, { tone: 'hi' });
  slab('display.bezel-right', 'display', plan(117, -49, 5, 3, .5), 31, 85, { tone: 'hi' });
  slab('display.bezel-top', 'display', plan(-3, -49, 120, 3, .5), 108.5, 7.5, { tone: 'hi' });
  slab('display.bezel-bottom', 'display', plan(-3, -49, 120, 3, .5), 31, 10, { tone: 'hi' });
  const screenMarkup = `<g transform="${k.sideMatrix([-3, -48], 108.5, P, 'left')}"><defs><clipPath id="screen-clip"><rect width="120" height="67.5" rx=".6"/></clipPath><linearGradient id="scene-gradient" x2="1" y2="1"><stop stop-color="#ff00cc"/><stop offset=".5" stop-color="#8000e6"/><stop offset="1" stop-color="#e633ff"/></linearGradient></defs><g clip-path="url(#screen-clip)"><rect width="120" height="67.5" fill="#0c0d0e"/><g id="viewing-content"><image id="painting-image" width="120" height="67.5" preserveAspectRatio="xMidYMid meet" href="${catalog.paintings[0].image}"/><rect id="gradient-image" width="120" height="67.5" fill="url(#scene-gradient)" visibility="hidden"/></g><g id="closed-screen" opacity="0"><rect width="120" height="67.5" fill="#111214"/><path d="M54 29V24a6 6 0 0 1 12 0v5M51 29h18v15H51Z" fill="none" stroke="#8b8b88" stroke-width=".8"/></g></g></g>`;
  // The glazing touches the case. The image is inset within the bezel aperture.
  slab('display.glazing', 'display', plan(-3, -49, 120, 1, .1), 41, 67.5, { tone: 'lo', bevel: 0, detail: screenMarkup });
  for (const [i, x] of [26, 63].entries()) {
    const p = plan(x, -58, 29, 18, 1.5);
    slab(`images.cache${i}`, 'images', p, 0, 10, { detail: screws(p, 10, 2.8) + inset(p, 10, 5),
      inner: line(k.sideSeam(p, 4, P, 5)) });
  }

  const history = plan(62, 11, 79, 49, 2);
  slab('recents.tray', 'recents', history, 0, 5, { detail: screws(history, 5) });
  for (const y of [11, 56]) slab(`recents.wall${y}`, 'recents', plan(62, y, 79, 4, .7), 5, 12);
  for (let i = 0; i < catalog.limits.recents; i++) {
    const p = plan(69 + i * 6.5, 15, 1.7, 41, .3);
    slab(`recents.divider${i}`, 'recents', p, 5, 23, { id: `recent-${i}`, detail: inset(p, 28, .4), tone: 'lo', bevel: .2 });
  }
  for (const y of [-69, -14]) slab(`shelf.upright${y}`, 'shelf', plan(149, y, 7, 7, .5), 0, 48);
  const shelf = plan(142, -74, 21, 72, 1.5);
  slab('shelf.ledge', 'shelf', shelf, 48, 4, { detail: screws(shelf, 52) });
  for (let i = 0; i < catalog.limits.shelfRecents; i++) {
    slab(`shelf.card${i}`, 'shelf', plan(145, -69 + i * 8, 15, 2, .3), 52, 14, { id: `shelf-${i}`, tone: 'lo', bevel: .2,
      detail: faceRect(147, -67 + i * 8, 63, 11, 7, 'faint') });
  }

  // Solve the actual coordinated stroke; closing traverses these states backwards.
  const states = Array.from({ length: 21 }, (_, i) => ({ label: `stroke-${i}`, shares: { admission: Math.min(1, i / 10), carrier: Math.max(0, i / 10 - 1) } }));
  A.settle(R, P, { states });
  items.sort((a, b) => a.key - b.key);
  A.auditOrExit(R, P, { frames: states, apart: states.at(-1) });
  const scene = items.map(item => `<g class="machine-part" data-system="${item.group}" data-piece="${item.piece}" data-k="${item.key}" data-m="${item.move.join(',')}"${item.id ? ` id="${item.id}"` : ''}>${item.svg}</g>`).join('');
  const svg = k.figureSvg({ width, height, label: 'An archival slide-viewing bench: nine artwork slides and five palette chips feed one carrier. An admission shutter controls the viewing screen. Image cache cartridges, a ten-slot history rack, and eight Top Shelf mounts complete the return path.',
    body: `<path class="iso-halo" d="${k.haloOf(base, -18, 10, P)}"/><g id="machine-parts">${scene}</g>` });
  return { svg, P, partCount: items.length };
}
