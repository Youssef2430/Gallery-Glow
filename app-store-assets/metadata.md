# Gallery Glow — App Store Connect metadata draft

Draft for the redesigned lifetime-purchase build. Not submitted or uploaded.

On October 11, 2026, **Gallery Glow Lifetime** was created in App Store Connect at **US$9.99**. Product ID: `galleryglow.lifetime.v2`; Apple ID: `6821757736`. Apple reserved the original `galleryglow.lifetime` ID, so the app sells the replacement while honoring verified historical ownership. Localization, availability in all 175 listed regions, regional pricing, review screenshot, and product review notes are saved. The product remains **Prepare for Submission** and must accompany the updated app build. The current online app description says there are no purchases and must be replaced for this build.

## Screenshots for the previous submission

Uploaded framed promotional screenshots are in
`app-store-assets/promotional-tv-frame/` at 3840×2160.

Uploaded set:

1. `01-living-gallery.png` — home screen in Apple TV frame
2. `02-masterpieces-edge-to-edge.png` — full-screen Michelangelo
3. `03-iconic-works.png` — full-screen Munch
4. `04-classic-art-framed.png` — full-screen Botticelli
5. `05-browse-by-artist.png` — artist browsing
6. `06-directors-cut.png` — full-screen Hopper
7. `07-ambient-gradients.png` — ambient gradient

The second design revision uses rounded frames and bold gallery typography. Its native screenshots are in `artifacts/redesign-round2/screenshots/` and are awaiting visual approval; the product’s uploaded review screenshot still shows the first revision.

New native screenshots can be exported with the documented screenshot test in README.md. Use the new home, artist, artwork, and lifetime-pass screens for the next submission; the old uploaded set does not reflect this redesign.

## App Information

| Field | Value |
|---|---|
| Subtitle (30 chars max) | `Classic art on your TV` |
| Category | Entertainment (secondary: Lifestyle) |
| Content rights | Does not contain third-party content (all paintings are public domain) |
| Age rating questionnaire | Answer **None/No** to everything → rating 4+ |
| Price | Free |
| App Privacy | **Data Not Collected** (matches PrivacyInfo.xcprivacy: no tracking, no collected data) |
| Copyright | `2026 Youssef Chouay` |

## URLs

| Field | Value |
|---|---|
| Marketing URL | `https://youssef2430.github.io/Gallery-Glow/` |
| Support URL | `https://youssef2430.github.io/Gallery-Glow/support.html` |
| Privacy Policy URL | `https://youssef2430.github.io/Gallery-Glow/privacy.html` |

GitHub Pages deploys from `main`, folder `/docs`.

## Promotional Text (170 chars max)

> Turn your Apple TV into a living art gallery. Wide-screen masterpieces from
> Hopper, Monet, Botticelli and more — in stunning full screen, all day long.

## Description

> Gallery Glow turns your Apple TV into a living art gallery.
>
> Fill your screen with timeless masterpieces — Hopper's Nighthawks,
> Monet's Stacks of Wheat, Church's Heart of the Andes, Michelangelo's Creation
> of Adam, and more — beautifully presented edge to edge on your TV.
>
> FEATURES
>
> • Painting of the Day — a new masterpiece to enjoy full screen for free each day
> • Full-screen viewing — every brushstroke, edge to edge
> • Browse by artist — Klimt, Munch, Michelangelo, Hopper, Botticelli, Monet,
>   Church, Leutze, and Post
> • Director's Cut — a hand-picked selection of the collection's finest
> • Ambient gradients — five soothing animated color scenes for when you
>   want atmosphere without a frame
> • Top Shelf integration — your gallery starts right on the Apple TV home
>   screen
>
> ONE PURCHASE, YOURS FOREVER
>
> Browse freely and enjoy the Painting of the Day in full screen at no cost.
> Gallery Glow Lifetime is a single one-time purchase that unlocks every
> painting on any day, every gradient, and all future gallery additions.
> No subscriptions.

>
> All artwork is in the public domain, sourced from museum open-access
> collections.

## Keywords (100 chars max)

```
art,paintings,monet,hopper,museum,ambient,screensaver,frame tv,relax,classic,gradient,apple tv
```

## Account readiness

App Store Connect Business shows the Paid Apps Agreement as **Pending User Info**. Bank details are missing, along with Canadian GST/HST Form 506, U.S. Certificate of Foreign Status of Beneficial Owner, and U.S. Form W-8BEN information. The account holder must complete the applicable details. No banking or tax information was entered.

## In-app purchase setup

- Reference name and English display name: **Gallery Glow Lifetime**
- Product ID: `galleryglow.lifetime.v2`
- Apple ID: `6821757736`
- Type: **Non-Consumable**
- English description: **Full-screen art, ambient scenes and future additions.**
- Base price: **US$9.99**, with Apple regional equivalents; the app displays StoreKit’s localized price
- Family Sharing: **Off**; the app reads Apple’s setting and does not advertise sharing
- Review screenshot: **Uploaded** `08-lifetime-pass.png` from the new native 4K checkout
- Product review notes: **Saved** with exact purchase/restore entry points

## App Review notes (version-level draft)

> Browsing the collection and artist pages is free, as is full-screen playback of the current Painting of the Day from any entry point (including Top Shelf). The free work rotates by local calendar date; an open free viewing session can finish uninterrupted. No app account or sign-in is required. On the first screen, select **Explore lifetime** in the upper-right corner to see Gallery Glow Lifetime, or select a painting other than the daily free artwork or any ambient scene. Choose **Unlock lifetime** to open Apple's confirmation. The localized price is provided by the App Store.
>
> This is a single non-consumable purchase, not a subscription. It unlocks all paintings on any day, ambient scenes, and future additions. The daily free artwork already supports full-screen playback, including from Top Shelf. **Restore Purchase** is next to **Keep browsing** on the lifetime screen. An approved purchase or restore continues directly to the selected artwork. Back/Menu always returns to browsing. Owners see **Your lifetime pass** on the home screen.
>
> Please test the new build and its accompanying non-consumable together in the Apple sandbox. Earlier build 1.0 (5) removed payment; this build restores the purchase entry points and transaction flow.

Before submission, select the new build, attach the new product, confirm the configured product and agreement status, and update the online description, screenshots, and review notes. Test an actual sandbox purchase and restore with the Xcode local StoreKit configuration disabled. These steps have not been completed by the local simulator tests.
