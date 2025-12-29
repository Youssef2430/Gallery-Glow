# Gallery Glow

![Swift](https://img.shields.io/badge/Swift-F05138?style=flat&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-0A84FF?style=flat&logo=swift&logoColor=white)
![tvOS](https://img.shields.io/badge/tvOS-26.2%2B-000000?style=flat&logo=apple&logoColor=white)
![TVServices](https://img.shields.io/badge/TVServices-Top%20Shelf-000000?style=flat&logo=apple&logoColor=white)
![Combine](https://img.shields.io/badge/Combine-000000?style=flat&logo=apple&logoColor=white)

A tvOS art gallery + “screensaver” experience that highlights classic paintings and fluid gradient visuals, with Apple TV **Top Shelf** integration.

## Features
- **Painting of the Day** (deterministic selection based on the current date)
- **Browse by artist** (grid UI)
- **Full-screen painting view**
  - Play/Pause toggles an info overlay
  - Menu exits back to the gallery
- **Fluid gradient screensaver** (animated blobs + smooth palette transitions)
- **Top Shelf extension**
  - Shows “Painting of the Day” + a “Gallery” section on the Apple TV Home screen
  - Selecting a Top Shelf item deep-links into the app

### Top Shelf
To see Top Shelf content on Apple TV:
1. Move **Gallery Glow** into the **top row** of apps on the Home screen.
2. Focus the app icon to reveal Top Shelf content.

## Deep linking
The app registers a custom URL scheme: `galleryglow://`

Top Shelf items open the app using URLs like:
- `galleryglow://painting/<imageName>`

Where `<imageName>` matches the painting’s `imageName` value (and may be percent-encoded), e.g.
- `galleryglow://painting/Van%20Gogh%2Fself-portrait_1998.74.5`

Deep link handling lives in `Gallery Glow/Gallery_GlowApp.swift`.

## Adding or updating paintings
1. Add the image to `Gallery Glow/Assets.xcassets`.
2. Add a `Painting(...)` entry in `Gallery Glow/PaintingData.swift`.
3. Add/adjust the matching tuple in `Gallery Shelf/ContentProvider.swift`.
4. Create a Top Shelf-friendly image file named by replacing `/` with `_`.
   - Example: `Van Gogh/self-portrait_1998.74.5` → `Van Gogh_self-portrait_1998.74.5.jpg`

Note: Top Shelf extensions have tight memory budgets, so the extension uses **pre-sized** images (bundle file URLs) rather than decoding large asset-catalog images at runtime.

## Troubleshooting
### “Killed by the operating system because it is using too much memory” (Top Shelf)
If the Top Shelf extension gets jetsam-killed, ensure images used by the extension are small and loaded by URL (not via `UIImage(named:)` + re-encoding). See `Gallery Shelf/ContentProvider.swift`.
