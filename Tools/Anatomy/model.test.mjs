import test from 'node:test';
import assert from 'node:assert/strict';
import { readCatalog } from './catalog.mjs';
import { dayOrdinal, dailyPainting, initialState, present, reconcile, topShelfRecents } from './model.mjs';
const catalog = readCatalog();

test('daily selection follows the ordinal, including leap day and year reset', () => {
  assert.equal(dayOrdinal(new Date(2024, 1, 29)), 60);
  assert.equal(dayOrdinal(new Date(2024, 11, 31)), 366);
  assert.equal(dayOrdinal(new Date(2025, 0, 1)), 1);
  assert.equal(dailyPainting(catalog, 1), catalog.paintings.filter(p => p.directorsCut)[0]);
  assert.equal(dailyPainting(catalog, 10), dailyPainting(catalog, 1));
});

test('locked selections wait, do not enter recents, and resume on unlock', () => {
  const start = initialState(catalog, 1);
  const locked = present(catalog, start, catalog.palettes[0]);
  assert.equal(locked.selection, null);
  assert.equal(locked.pending, catalog.palettes[0]);
  assert.deepEqual(locked.recents, start.recents);
  const unlocked = reconcile(catalog, { ...locked, unlocked: true });
  assert.equal(unlocked.selection, catalog.palettes[0]);
  assert.equal(unlocked.pending, null);
  assert.equal(unlocked.recents[0], catalog.palettes[0]);
});

test('an admitted daily view survives midnight but reopening checks the new day', () => {
  const start = initialState(catalog, 1);
  const tomorrow = reconcile(catalog, { ...start, day: 2 });
  assert.equal(tomorrow.selection, start.selection);
  assert.equal(present(catalog, tomorrow, start.selection).selection, null);
  const pending = present(catalog, start, dailyPainting(catalog, 2));
  assert.equal(reconcile(catalog, { ...pending, day: 2 }).selection, dailyPainting(catalog, 2));
});

test('revoking a lifetime entitlement returns a nonfree view to the paywall', () => {
  const state = present(catalog, { ...initialState(catalog, 1), unlocked: true }, catalog.palettes[0]);
  const revoked = reconcile(catalog, { ...state, unlocked: false });
  assert.equal(revoked.selection, null);
  assert.equal(revoked.pending, catalog.palettes[0]);
});

test('history deduplicates, caps at 10, and Top Shelf resolves at most 8', () => {
  let state = { ...initialState(catalog, 1), unlocked: true };
  for (const item of [...catalog.paintings, ...catalog.palettes]) state = present(catalog, state, item);
  assert.equal(state.recents.length, 10);
  state = present(catalog, state, state.recents[4]);
  assert.equal(new Set(state.recents.map(p => p.id)).size, 10);
  assert.equal(topShelfRecents(catalog, state).length, 8);
  const dirty = { ...state, recents: [{ id: 'removed' }, state.recents[0], ...state.recents] };
  assert.equal(topShelfRecents(catalog, dirty)[0], state.recents[0]);
  assert.equal(new Set(topShelfRecents(catalog, dirty).map(p => p.id)).size, 8);
});
