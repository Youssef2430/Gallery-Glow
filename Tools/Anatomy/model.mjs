// A small, pure behavioral counterpart to GallerySession and RecentlyUsedManager.
// Rendering, StoreKit transactions, and native image loading are not simulated.
export function dayOrdinal(date) {
  return Math.round((Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) - Date.UTC(date.getFullYear(), 0, 1)) / 86400000) + 1;
}

export function dailyPainting(catalog, day) {
  const works = catalog.paintings.filter(item => item.directorsCut);
  return works[((day - 1) % works.length + works.length) % works.length];
}

export function isFree(catalog, state, item) {
  return item?.kind === 'painting' && item.id === dailyPainting(catalog, state.day).id;
}

export function canAccess(catalog, state, item) {
  return Boolean(item && (state.unlocked || isFree(catalog, state, item)));
}

export function present(catalog, state, item) {
  if (!canAccess(catalog, state, item)) {
    return { ...state, selection: null, pending: item, freeViewingID: null };
  }
  return {
    ...state, selection: item, pending: null,
    freeViewingID: isFree(catalog, state, item) ? item.id : null,
    recents: [item, ...state.recents.filter(old => old.id !== item.id)].slice(0, catalog.limits.recents),
  };
}

export function reconcile(catalog, state) {
  if (state.pending && canAccess(catalog, state, state.pending)) return present(catalog, state, state.pending);
  if (state.selection && state.selection.id !== state.freeViewingID && !canAccess(catalog, state, state.selection)) {
    return { ...state, pending: state.selection, selection: null };
  }
  return state;
}

export function topShelfRecents(catalog, state) {
  const current = new Set([...catalog.paintings, ...catalog.palettes].map(item => item.id));
  return state.recents.filter((item, i, rows) => current.has(item.id) && rows.findIndex(row => row.id === item.id) === i).slice(0, catalog.limits.shelfRecents);
}

export function initialState(catalog, day) {
  return present(catalog, { day, unlocked: false, selection: null, pending: null, freeViewingID: null, recents: [] }, dailyPainting(catalog, day));
}
