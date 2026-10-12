# Gallery Glow — Glow Frame

The icon pairs a luminous gallery frame with an abstract sunset, connecting the app's classic paintings and ambient gradients. Champagne gold, coral and violet sit on a deep plum background. The website favicon reduces the same idea to a frame, sun and two flowing hills for legibility at 16 pixels.

## Deliverables

- `artwork.png`: original transparent artwork, generated with the built-in image generation tool.
- `icon-tvos.png`: 1280 × 768 flattened preview of the installed Apple TV icon.
- `icon-square.png`: 1024 × 1024 square project icon.
- The Xcode brand asset catalog contains Back, Middle (ambient glow), and Front layers at 400 × 240, 800 × 480, and 1280 × 768.
- `../../docs/favicon.svg`: editable, simplified favicon; the PNG files and three-size ICO are rendered from this SVG.
- `../../docs/apple-touch-icon.png`: 180 × 180 square icon for saved website links.
- Both support and privacy pages reference the relative favicon and touch-icon paths, including when hosted under a GitHub Pages project subpath.

## Regenerate

On macOS, from the repository root:

```sh
swift AppIcon/ExportGlowFrame.swift
```

The script uses AppKit, Core Graphics, and ImageIO. No third-party packages or API keys are needed. It exports assets into the existing Xcode icon slots, updates the middle-layer manifests, and writes the website icons. Earlier icon concepts remain in `AppIcon/` for reference. The full-bleed tvOS background is opaque; foreground and glow layers preserve transparency. Outer corner masking is left to tvOS.

Design and packaging references: [Apple app icon guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons) and [layered image guidance](https://developer.apple.com/design/human-interface-guidelines/images). The source art is newly generated rather than downloaded from a third-party icon collection.

## Artwork generation prompt

Tool: built-in `image_gen`, with `transparent_background: true`. The following prompt produced the saved `artwork.png`:

```text
Use case: logo-brand
Asset type: Original Gallery Glow Apple TV app icon foreground artwork, isolated on genuine transparency. One image, square canvas 1024x1024.
Primary request: A luminous small gallery picture, a sculptural warm champagne-gold frame enclosing an abstract sunset made from fluid flowing color. Gallery Glow displays classic paintings and ambient gradient art.
Subject: A single centered front-facing rectangular gallery frame, slightly wider than tall (about 1.15:1), with gently rounded corners, a substantial polished bevel and fine inner rim. Inside the frame is a minimal luminous apricot sun in the upper right over two broad sweeping velvet-like hills, back hill lilac-violet, front hill deep indigo flowing up from the bottom left and down to the right, against a coral-to-plum sunset sky. The artwork fills the frame with no white mat. The sun is a clean circular disk. The flowing hills should have rich silky gradients and feel like abstract fine art, not a stock mountain symbol.
Style/medium: Premium tactile 3D app icon, precise geometry, art-directed restrained reflections, softly glowing edges, quiet museum quality, crisp readable silhouette. Almost straight-on, no visible perspective tilt.
Composition/framing: The entire framed object occupies 82% of the canvas width and 72% of the height, perfectly centered with generous transparent padding on all sides. Render only the frame and the picture inside it, with a faint warm halo close to its edges.
Color palette: Champagne gold, apricot, soft coral, orchid violet, rich plum, deep indigo.
Text: None.
Constraints: Actual transparent pixels outside the object, opaque colored painting inside. No background plate, no surrounding room, no wall, no floor, no square app tile, no lettering, no easel, no stars or sparkles, no watermark. Bold simple shapes that read at small scale. This is original artwork, not a copy of any existing app icon.
```
