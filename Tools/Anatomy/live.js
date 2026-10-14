const $ = selector => document.querySelector(selector);
const stage = $('.iso-stage');
const partsRoot = $('#machine-parts');
const parts = [...document.querySelectorAll('.machine-part')].map(node => ({ node, group: node.dataset.system, piece: node.dataset.piece, key: Number(node.dataset.k), move: node.dataset.m.split(',').map(Number) }));
const allSelections = [...CATALOG.paintings, ...CATALOG.palettes];
const reduce = matchMedia('(prefers-reduced-motion: reduce)');
const startDate = new Date();
let date = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
let state = initialState(CATALOG, dayOrdinal(date));
let selectedSystem = 0, tour = !reduce.matches, tourClock = 0, holdUntil = 0;
let stroke = 1, opacity = 1, displayedID = null;
let frame = 0, lastTime = 0, visible = false, frameCount = 0, order = '';
const camera = (() => {
  const a = PROJECTION.azimuth * Math.PI / 180, e = PROJECTION.elevation * Math.PI / 180;
  return { sa: Math.sin(a), ca: Math.cos(a), se: Math.sin(e), ce: Math.cos(e), scale: PROJECTION.scale * Math.sqrt(1.6) };
})();
const V = [camera.ca * camera.ce, camera.sa * camera.ce, camera.se];
const dot = (a, b) => a.reduce((sum, value, i) => sum + value * b[i], 0);
const smooth = (value, target, dt, seconds) => {
  if (reduce.matches || Math.abs(target - value) < .0005) return target;
  return value + (target - value) * (1 - Math.exp(-dt / seconds));
};

function inspect(index) {
  selectedSystem = (index + SECTIONS.length) % SECTIONS.length;
  const section = SECTIONS[selectedSystem];
  $('#system-title').textContent = section.title;
  $('#system-stat').textContent = section.stat;
  $('#system-description').textContent = section.text;
  $('#system-detail').textContent = section.detail;
  document.querySelectorAll('[data-inspect]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.inspect === section.id)));
  for (const part of parts) part.node.toggleAttribute('data-focus', part.group === section.id);
  $('#source-links').replaceChildren(...section.sources.map(source => {
    const link = document.createElement('a');
    link.textContent = source.label + ' ↗'; link.href = source.url;
    link.target = '_blank'; link.rel = 'noopener noreferrer';
    return link;
  }));
}

function refresh() {
  const current = state.selection || state.pending;
  $('#selection').value = current?.id || dailyPainting(CATALOG, state.day).id;
  $('#lifetime').setAttribute('aria-pressed', String(state.unlocked));
  $('#calendar-label').textContent = date.toLocaleDateString('en', { month: 'short', day: 'numeric', year: 'numeric' }) + ' · day ' + state.day;
  $('#tour').setAttribute('aria-pressed', String(tour));
  $('#tour').textContent = reduce.matches ? 'Motion reduced' : tour ? 'Pause tour' : 'Start tour';
  $('#tour').disabled = reduce.matches;
  let summary;
  if (state.pending) summary = `${state.pending.title} is waiting at the shutter. Lifetime unlock will resume this selection. History is unchanged.`;
  else if (state.selection && state.selection.id === state.freeViewingID && !isFree(CATALOG, state, state.selection)) summary = `${state.selection.title} stays open after midnight. Today’s free work is now ${dailyPainting(CATALOG, state.day).title}; reopening the old work checks access again.`;
  else summary = `${state.selection.title} is admitted ${state.unlocked ? 'with lifetime access' : 'as today’s free artwork'}. ${state.recents.length} of ${CATALOG.limits.recents} history slots used; ${topShelfRecents(CATALOG, state).length} returned to Top Shelf.`;
  $('#demo-status').textContent = summary;
  for (let i = 0; i < CATALOG.limits.recents; i++) {
    $(`#recent-${i}`).toggleAttribute('data-occupied', i < state.recents.length);
    $(`#recent-${i}`).toggleAttribute('data-empty', i >= state.recents.length);
  }
  for (let i = 0; i < CATALOG.limits.shelfRecents; i++) {
    $(`#shelf-${i}`).toggleAttribute('data-occupied', i < topShelfRecents(CATALOG, state).length);
    $(`#shelf-${i}`).toggleAttribute('data-empty', i >= topShelfRecents(CATALOG, state).length);
  }
  stage.setAttribute('aria-description', summary);
  run();
}

function hold() { holdUntil = performance.now() + 12000; tourClock = 0; run(); }
function choose(item) {
  if (!item) return;
  hold();
  state = present(CATALOG, state, item);
  inspect(state.pending ? 2 : 3);
  refresh();
}

function setScreen(item) {
  if (!item) return;
  if (item.kind === 'painting') {
    $('#painting-image').setAttribute('href', item.image);
    $('#painting-image').setAttribute('preserveAspectRatio', item.directorsCut ? 'xMidYMid slice' : 'xMidYMid meet');
    $('#painting-image').setAttribute('visibility', 'visible');
    $('#gradient-image').setAttribute('visibility', 'hidden');
  } else {
    $('#painting-image').setAttribute('visibility', 'hidden');
    $('#gradient-image').setAttribute('visibility', 'visible');
    const stops = document.querySelectorAll('#scene-gradient stop');
    stops.forEach((stop, i) => stop.setAttribute('stop-color', item.colors[i]));
  }
  displayedID = item.id;
}

function draw() {
  const shares = { admission: Math.min(stroke * 2, 1), carrier: Math.max(0, stroke * 2 - 1) };
  for (const part of parts) {
    const share = shares[part.piece] || 0;
    const [x, y, z] = part.move.map(value => value * share);
    part.node.setAttribute('transform', `translate(${(x * camera.sa - y * camera.ca) * camera.scale} ${((x * camera.ca + y * camera.sa) * camera.se - z * camera.ce) * camera.scale})`);
    part.depth = part.key + dot(part.move, V) * share;
  }
  const sorted = [...parts].sort((a, b) => a.depth - b.depth);
  const nextOrder = sorted.map(part => part.key).join(',');
  if (nextOrder !== order) {
    const fragment = document.createDocumentFragment();
    sorted.forEach(part => fragment.append(part.node));
    partsRoot.append(fragment); order = nextOrder;
  }
  $('#viewing-content').setAttribute('opacity', String(opacity));
  $('#closed-screen').setAttribute('opacity', String(state.pending ? 1 - opacity : 0));
  const changing = state.selection ? stroke < .999 || opacity < .999 || displayedID !== state.selection.id : stroke > .001;
  const readout = changing ? (state.selection ? 'Admitting selection…' : 'Returning to access gate…') : state.pending ? `Gate closed · ${state.recents.length} saved` : `Viewing · ${state.recents.length}/${CATALOG.limits.recents} saved · ${topShelfRecents(CATALOG, state).length}/${CATALOG.limits.shelfRecents} shelf`;
  if ($('[data-readout]').textContent !== readout) $('[data-readout]').textContent = readout;
}

function tick(now) {
  frame = 0;
  if (!visible || document.hidden) { lastTime = 0; return; }
  const dt = lastTime ? Math.min((now - lastTime) / 1000, 1 / 30) : 1 / 60;
  lastTime = now;
  frameCount++;
  stroke = smooth(stroke, state.selection ? 1 : 0, dt, .23);
  if (state.selection?.id !== displayedID) {
    opacity = smooth(opacity, 0, dt, .14);
    if (opacity === 0 && state.selection) setScreen(state.selection);
  } else opacity = smooth(opacity, state.selection && stroke > .92 ? 1 : 0, dt, .25);
  if (!state.selection) opacity = smooth(opacity, 0, dt, .14);
  if (reduce.matches && state.selection) { setScreen(state.selection); opacity = 1; }
  if (tour && !reduce.matches && now > holdUntil && !stage.matches(':hover, :focus') && !$('#selection').matches(':focus')) {
    tourClock += dt;
    if (tourClock > 4.5) { inspect(selectedSystem + 1); tourClock = 0; }
  }
  draw();
  const moving = stroke !== (state.selection ? 1 : 0) || opacity !== (state.selection ? 1 : 0) || (state.selection && displayedID !== state.selection.id);
  if (moving || (tour && !reduce.matches)) frame = requestAnimationFrame(tick);
}

function run() {
  if (!frame && visible && !document.hidden) { lastTime = 0; frame = requestAnimationFrame(tick); }
}

$('#selection').addEventListener('change', event => choose(allSelections.find(item => item.id === event.target.value)));
$('#lifetime').addEventListener('click', () => { hold(); state = reconcile(CATALOG, { ...state, unlocked: !state.unlocked }); inspect(2); refresh(); });
$('#today').addEventListener('click', () => choose(dailyPainting(CATALOG, state.day)));
$('#next-day').addEventListener('click', () => {
  hold(); date.setDate(date.getDate() + 1);
  state = reconcile(CATALOG, { ...state, day: dayOrdinal(date) }); inspect(0); refresh();
});
$('#reset').addEventListener('click', () => {
  hold(); date = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate());
  state = initialState(CATALOG, dayOrdinal(date)); inspect(0); refresh();
});
$('#tour').addEventListener('click', () => { tour = !tour; holdUntil = 0; tourClock = 0; refresh(); });
$('#appearance').addEventListener('click', () => {
  document.body.dataset.theme = document.body.dataset.theme === 'light' ? 'dark' : 'light';
  document.querySelector('meta[name=color-scheme]').content = document.body.dataset.theme;
});
document.querySelectorAll('[data-inspect]').forEach(button => button.addEventListener('click', () => { hold(); inspect(SECTIONS.findIndex(section => section.id === button.dataset.inspect)); }));
for (const part of parts) {
  const index = SECTIONS.findIndex(section => section.id === part.group);
  if (index < 0) continue;
  part.node.addEventListener('pointerenter', event => { if (event.pointerType === 'mouse') { hold(); inspect(index); } });
  part.node.addEventListener('click', () => { hold(); inspect(index); });
}
stage.addEventListener('keydown', event => {
  if (!['ArrowLeft', 'ArrowRight', 'Home', 'End', 'Enter', ' '].includes(event.key)) return;
  event.preventDefault(); hold();
  if (event.key === 'ArrowLeft') inspect(selectedSystem - 1);
  if (event.key === 'ArrowRight') inspect(selectedSystem + 1);
  if (event.key === 'Home') inspect(0);
  if (event.key === 'End') inspect(SECTIONS.length - 1);
  if (!reduce.matches && (event.key === 'Enter' || event.key === ' ')) { tour = !tour; holdUntil = 0; refresh(); }
});
new IntersectionObserver(entries => {
  visible = entries.at(-1).isIntersecting;
  if (!visible && frame) { cancelAnimationFrame(frame); frame = 0; }
  run();
}, { rootMargin: '80px 0px' }).observe(stage);
document.addEventListener('visibilitychange', () => {
  if (document.hidden && frame) { cancelAnimationFrame(frame); frame = 0; }
  run();
});
reduce.addEventListener('change', () => { if (reduce.matches) tour = false; refresh(); });
setScreen(state.selection); inspect(0); refresh(); draw();
// Read-only inspection for verification; all state changes use the visible controls.
window.__anatomy = { get state() { return structuredClone(state); }, get stroke() { return stroke; }, get frames() { return frameCount; }, get touring() { return tour; }, get visible() { return visible; } };
