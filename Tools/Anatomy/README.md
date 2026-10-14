# Gallery Glow anatomy

A Figure: a self-contained interactive SVG explanation of the native tvOS app.
The object is an archival slide-viewing bench. A carrier brings a selection to
one viewing station; an admission shutter opens for today's painting or a
lifetime entitlement. The archive and index racks explain local content and
the return path through recent history to Apple TV's Top Shelf.

## Planned parts (before geometry)

- Base: four rubber feet, a beveled deck, inset perimeter groove, four corner
  fasteners, an engraved nameplate, and a front ruler strip.
- Catalog: cassette floor, two retaining walls, nine individual artwork slides,
  a palette tray, and five gradient chips.
- Selection: two guide rails, two end stops, a carrier, two bearing shoes, and
  the selected slide.
- Admission: two mounting feet, two guide posts, one crosshead, one sliding
  shutter, and its grip.
- Presentation: two mounting shoes, two uprights, a screen body, four bezel
  rails, one recessed viewing surface, and two image-cache cartridges.
- History: an index tray, two retaining cheeks, and ten file dividers.
- Top Shelf: two uprights, one shelf, and eight recent-item card mounts.

This is roughly 76 solids, with face seams, screw rings, ventilation slots,
card insets, detents, and scale marks belonging to those solids. The screen is
the single illuminated subject. No shaders or exploded view are needed.

## World and motion

World x follows the feed rails, y runs across the bench, and z is up. A camera
at 48° azimuth and 34° elevation reveals the magazines and viewing surface.
The carrier slides in x and the shutter rises in z. Both follow eased targets;
their depth order is solved over the full travel. Every drawn solid records
its actual rounded plan for the geometry audit.

## Build

Run `node Tools/Anatomy/build.mjs --audit` from the repository root. This writes
`docs/anatomy.html` and `docs/anatomy-light.html`, both offline and dependency-free
at runtime. Build-time thumbnail generation uses macOS `sips`. Catalog entries,
palette RGB values, and implementation limits are extracted from Swift sources.
Run `node --test Tools/Anatomy/model.test.mjs` to verify the demo's access and
history behavior. The demo models selection, admission, midnight reconciliation,
and history; it does not contact StoreKit or execute the native rendering code.

The SVG geometry kit in `vendor/` is copied from Ryan's MIT-licensed Anatomy skill.
Local modifications, if any, are documented in `vendor/NOTICE`.
The page's source references are pinned to the checkout's commit at build time.
Use the Anatomy skill's `scripts/capture.mjs`, `scripts/drive.mjs`, and
`scripts/lines.mjs` for visual and line-end verification. Verification images
belong in the repository's ignored `artifacts/anatomy/` directory.
