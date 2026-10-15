# Gallery Glow

Classic art and ambient scenes for Apple TV. A space for art. A moment for you.

[Website](https://yssf-c.github.io/Gallery-Glow/) · [Support](https://yssf-c.github.io/Gallery-Glow/support.html) · [Contact](https://youssefchouay.com) · [Privacy](https://yssf-c.github.io/Gallery-Glow/privacy.html)

![Gallery Glow: great art, right at home](docs/assets/gallery-glow-social.jpg)

Browse nine artists, enjoy a different daily painting in full screen for free,
and make the whole collection yours with Gallery Glow Lifetime. One purchase
unlocks every artwork, five animated ambient scenes, and future gallery additions.
No subscription, ads, analytics, or app account.

SwiftUI · tvOS 18+ · Light and dark appearance · Apple TV Top Shelf · StoreKit 2

![The current Apple TV app](docs/assets/gallery-home.jpg)

## Run and test

Open `Gallery Glow.xcodeproj` in a current Xcode with the tvOS platform installed.
Select the **Gallery Glow** scheme and an Apple TV simulator or paired Apple TV.

The Debug scheme uses `Gallery GlowTests/GalleryGlow.storekit` for local purchase
testing. To test App Store Connect products from Xcode, set **Edit Scheme → Run →
Options → StoreKit Configuration → None** and use a Sandbox Apple Account.
TestFlight uses Apple's sandbox automatically; test purchases do not charge you.
The current non-consumable ID is `galleryglow.lifetime.v2`. Verified ownership of
the historical `galleryglow.lifetime` product remains supported.

See [CONTRIBUTING.md](CONTRIBUTING.md) for CI, local validation, and review rules.
All changes go through PRs. `yssf-c` must approve other authors' current changes;
his own PRs need no approval. All PRs still need passing checks.
