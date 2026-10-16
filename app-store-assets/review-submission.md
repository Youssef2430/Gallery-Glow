# App Review resubmission — 1.0 (8)

The October 16, 2026 rejection (submission
`10f808eb-ab25-4e96-83c2-c12170636b80`) requires the in-app purchase to be
submitted for review and a new binary uploaded. A successful TestFlight upload
alone does not resolve Guideline 2.1(b).

## Verified submission

Submitted October 16, 2026 at 7:14 PM America/Toronto. App Store Connect confirmed
**2 Items Submitted** in [submission b718760f-1e62-47bb-ab23-b2f3dd1a9963](https://appstoreconnect.apple.com/apps/6779811163/distribution/reviewsubmissions/details/b718760f-1e62-47bb-ab23-b2f3dd1a9963):

- **tvOS App 1.0 (8): Waiting for Review**.
- **Gallery Glow Lifetime: Waiting for Review**.

The existing product screenshot was present and visually verified. Product and
app review notes now identify build 8, the product ID, purchase/restore entry
points, and the Apple TV review platform. The old rejected app-only submission
was cancelled so the app could join the IAP in this new submission. No reply was
sent to App Review; the draft below is available if needed. These statuses record
the submission-time result, not subsequent approval.

## Product and review attachment

- App: Gallery Glow, Apple ID `6779811163`, **tvOS** version **1.0**, build **8**.
- Product: **Gallery Glow Lifetime**, non-consumable `galleryglow.lifetime.v2`,
  Apple ID `6821757736`.
- Display name: `Gallery Glow Lifetime`.
- Description: `Full-screen art, ambient scenes and future additions.`
- Review screenshot: [iap-review-screenshot.png](iap-review-screenshot.png),
  1920 × 1080, showing the purchase price, benefits, and Restore Purchase.
- Review notes: use the App Review notes in [metadata.md](metadata.md).
- Keep the existing price and availability. The historical
  `galleryglow.lifetime` is recognized only for existing verified ownership.

## Submit together

1. Open Gallery Glow → Monetization → In-App Purchases → Gallery Glow Lifetime.
   Verify the exact product ID above, localization, price, availability, and
   **App Review Information → Screenshot**. Upload the review screenshot if
   missing and save. Resolve any Missing Metadata or Developer Action Needed
   status before proceeding.
2. Upload build 8 and wait for processing. Select it on the **tvOS 1.0** version
   page. Complete any export-compliance questions using the app's actual settings.
3. Use **Add for Review** on the product and include tvOS version 1.0 in the
   **same draft submission**. In App Review, inspect the items: both the app
   version (build 8) and `galleryglow.lifetime.v2` must be listed.
4. For an existing rejected submission, edit the rejected items, save, and use
   **Update Review** where offered before **Resubmit to App Review**. Otherwise
   use **Submit for Review** on the completed draft.
5. Confirm both items were submitted and record their resulting statuses. An
   IAP that remains Ready to Submit has not been submitted. A screenshot on disk
   or on the app's listing does not establish that the IAP attachment is present.

The review message lists an iPhone, but this app is tvOS-only. The review notes
explicitly request Apple TV review. Do not add an iOS platform to address that
discrepancy.

## Validation

Run `python3 Tools/Release/validate.py` and create a signed Release archive.
Before release, verify purchase, cancellation, relaunch, and restoration with
the App Store product through TestFlight on Apple TV. Xcode's local StoreKit
configuration does not establish App Store Connect readiness or approval.

## Reply draft

Send only after confirming the submission contains both items:

> Hello App Review,
>
> We have uploaded version 1.0 (8) and submitted Gallery Glow Lifetime
> (`galleryglow.lifetime.v2`, Apple ID 6821757736) together with the tvOS app
> version. The non-consumable includes its App Review screenshot and metadata.
>
> Gallery Glow is an Apple TV app for tvOS 18 or later. On Apple TV, select
> Explore lifetime from the home screen to access Unlock lifetime and Restore
> Purchase. No app account is required. Please review the app and its in-app
> purchase together. Thank you.

## Apple references

- [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/)
- [In-App Purchase information](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/)

The checklist and reply draft are reusable preparation materials. The verified
submission section above records the actual App Store Connect result.
