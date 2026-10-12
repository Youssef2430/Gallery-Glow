# Gallery Glow

Classic art and ambient gradients for Apple TV.

[Website](https://youssef2430.github.io/Gallery-Glow/)

Today’s artwork is free. Lifetime unlocks every painting and gradient.

SwiftUI · tvOS 18+ · Light & dark mode

Open `Gallery Glow.xcodeproj` in Xcode to run or test.

Regenerate the Apple TV shelf cards after changing the catalog, palettes, or
preview design with `./generate_topshelf_images.sh` (macOS + Xcode). The renderer
uses the app’s catalog, gallery colors, and gradient palettes and writes
888 × 500 JPEGs to `Gallery Shelf/TopShelfImages`. The cards use a warm paper
background, centered framed artwork, artist credits, and an arrow. Daily variants
add a centered “On view today” / “Free today” header. tvOS supplies the only
painting title below the card. Artwork is fitted without cropping.
Commit the generated images with the source changes.
