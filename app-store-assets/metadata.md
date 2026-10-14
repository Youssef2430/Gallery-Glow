# Gallery Glow — build 1.0 (6)

Release package prepared October 14, 2026. This document is the source for the
updated listing; publishing the website or uploading a TestFlight build does not
submit the app for App Review.

## URLs and contact

| App Store Connect field | Value |
|---|---|
| Marketing URL | `https://yssf-c.github.io/Gallery-Glow/` |
| Support URL | `https://yssf-c.github.io/Gallery-Glow/support.html` |
| Privacy Policy URL | `https://yssf-c.github.io/Gallery-Glow/privacy.html` |
| Public contact page | `https://yssf-c.github.io/Gallery-Glow/support.html#contact` |
| Public support email | `youssefcurry3@gmail.com` |

Keep the App Review contact's actual name, phone, and email in their dedicated
fields; a website is not a replacement for those private review-contact fields.
GitHub Pages publishes `main`, folder `/docs`.

## Current screenshot set

Use the eight 3840 × 2160 PNGs in `app-store-assets/release-1.0-6/`, in filename
order. They wrap fresh screenshots of the current app in a coordinated paper,
ink, and gold presentation. Images elsewhere in `app-store-assets/` are historical
and must not be mixed into this set.

1. `01-living-gallery.png` — actual home and daily free artwork
2. `02-great-art.png` — Botticelli in full screen
3. `03-the-artists.png` — artist browsing
4. `04-nighthawks.png` — Hopper in full screen
5. `05-ambient-scenes.png` — Aurora ambient scene
6. `06-masterpieces.png` — Michelangelo in full screen
7. `07-quiet-moments.png` — Munch in full screen
8. `08-lifetime.png` — lifetime purchase and restore screen

Use the native `08-lifetime-pass.png` capture as the IAP review screenshot.
[README.md](../README.md) documents capture and regeneration.

## App Information

- Name: **Gallery Glow**
- Subtitle: **Classic art on your TV**
- Primary category: **Entertainment**; secondary: **Lifestyle**
- App price: **Free**, with an optional non-consumable purchase
- App privacy: **Data Not Collected**
- Copyright: **2026 Youssef Chouay**
- Platform: **Apple TV, tvOS 18 or later**

## Promotional text

Turn your Apple TV into a quiet gallery. A different painting is free every day. Unlock every artwork and five ambient scenes with one lifetime purchase.

## Description

A space for art. A moment for you.

Gallery Glow turns your Apple TV into a private gallery of classic paintings and
gently animated color. Give your biggest screen something beautiful to show.

START WITH TODAY
Browse the collection freely. Enjoy the Painting of the Day in full screen at no
cost, with a different work selected each day.

EXPLORE THE COLLECTION
Discover works by Botticelli, Monet, Hopper, Klimt, Munch, Michelangelo, Church,
Leutze, and Post. Browse by artist, revisit your favorites in Recently Viewed,
and open artwork directly from Apple TV's Top Shelf.

CHANGE THE ATMOSPHERE
Choose from five animated ambient scenes: Ocean Blue, Sunrise Gold, Aurora,
Pink Orange, and Magenta Purple. Pause and resume using your Apple TV remote.

ONE PURCHASE. YOURS TO KEEP.
Gallery Glow Lifetime unlocks every painting on any day, every ambient scene,
and future additions to the collection. It is a single purchase, with no
subscription. Restore your access with the same Apple Account.

MADE FOR A QUIETER SCREEN
Light and dark appearance. No ads, analytics, or app account. Artwork is bundled
with the app, ready to view on your Apple TV.

Explore Gallery Glow: https://yssf-c.github.io/Gallery-Glow/
Help and contact: https://yssf-c.github.io/Gallery-Glow/support.html

## Keywords

art,paintings,monet,hopper,museum,ambient,screensaver,frame tv,relax,classic,gradient,apple tv

## What's new

A refreshed gallery with light and dark appearance, a free daily painting,
redesigned Top Shelf previews, and a one-time lifetime unlock with purchase
restoration. Improved artwork loading, remote navigation, and ambient scenes.

## In-app purchase

- Reference/display name: **Gallery Glow Lifetime**
- Product ID: `galleryglow.lifetime.v2`
- Apple ID: `6821757736`
- Type: **Non-Consumable**
- Description: **Full-screen art, ambient scenes and future additions.**
- Configured base price: **US$9.99**; the app displays Apple's localized price
- Family Sharing: **Off**; only advertise it if enabled for the product
- Historical product: `galleryglow.lifetime`, still honored for verified owners

The supplied October 13 account screenshot shows the Paid Apps Agreement,
banking, tax forms, and compliance sections as **Active**. The previous
“Pending User Info” note is obsolete. Account readiness alone does not verify an
actual sandbox purchase or establish product approval.

## App Review notes

Browsing the collection and artist pages is free. Full-screen playback of the
current Painting of the Day is free from every entry point, including Top Shelf.
The free work rotates by local calendar date. A viewing session already admitted
for free can finish uninterrupted. No app account or sign-in is required.

On the home screen, select **Explore lifetime** in the upper-right corner, or
select another painting or any ambient scene. Select **Unlock lifetime** to open
Apple's purchase confirmation. The price is supplied by the App Store.

This is a non-consumable, not a subscription. It unlocks all paintings on any day,
ambient scenes, and future collection additions. **Restore Purchase** appears
beside **Keep browsing**. If the paywall was opened for an artwork, a successful
purchase or restore continues to that artwork. Back/Menu returns to browsing.
Owners see **Your lifetime pass** on the home screen.

Test the new build and its accompanying product together in Apple's sandbox.
The previous 1.0 (5) submission removed payment; this build restores the purchase
entry points and transaction flow.

## Before App Review submission

Select the new processed build, attach the non-consumable, save the URLs and
copy above, replace the old screenshots, and verify purchase, cancellation,
relaunch, and restoration through TestFlight on Apple TV. Local StoreKit tests
exercise the implementation but do not validate the App Store Connect product.
