# Project status — RoomFinder LR

_Last updated: 17 October 2026_

## Where things stand
- **Phase 1 (Build MVP)** — first full version of the code written: search, filters, listing page, sign-in, saves, reports, add/edit listing with photos, my places, admin review and reports.
- Not yet compiled: the code was written without a Flutter SDK available. **The first GitHub Actions run is the first compile.** If `flutter analyze` or the build fails, copy the error lines and ask for a fix.
- Firebase project, Cloudinary account and GitHub secrets: **not set up yet** (see README steps 1–7).

## Design (17 Oct 2026)
- Identity taken from Monrovia: Atlantic blue `#0E4D64` (headers, buttons), zinc-roof grey `#EEF2F3` (background), sign yellow `#F5C02E` (price tags, like hand-painted "Room for rent" signs), palm green `#2F7D4F` (verified, WhatsApp), laterite red `#B5482E` (warnings only).
- Fonts: Bricolage Grotesque for headings and prices, Figtree for text (google_fonts; system font if offline on first launch).
- Signature: yellow price tag on every listing photo. Photo-first search cards, blue header with community picker, listing page with full-width gallery, fact tiles and amenity list, numbered steps in the Add a place form.
- All colours and styles live in `lib/theme.dart`.

## Decisions made
- Flutter for Android + web from one codebase; website hosted on GitHub Pages.
- Firebase Auth (Google + email/password), Firestore on the free Spark plan; no Cloud Functions or Cloud Storage (both need Blaze).
- Photos on Cloudinary free plan via an unsigned upload preset; shrunk on the phone to ~1280 px, 70% quality.
- Firebase initialised from `--dart-define` values, so no `google-services.json` and no Gradle plugin.
- Every new or edited listing goes to the admin review queue; "verified" only after a visit or video call.
- Freshness: listings must be confirmed every 14 days or they leave search (handled in the query, no server job).
- Contact numbers stored separately (`listingContacts`) to allow pay-to-unlock later.
- Everything free during the pilot; charging starts after 100 verified listings and 1,000 renters.

## Next steps
1. Set up Firebase, Cloudinary, secrets; run the first build and fix any compile errors.
2. Test on a cheap Android phone and in a phone browser.
3. Add a fixed release keystore so Google sign-in works in the Android app.
4. Pilot: 2–3 communities, 2 scouts, aim for 100 verified listings.
5. Later: "still free?" reminders (GitHub Actions scheduled job + FCM), mobile money unlocks and featured listings, rent alerts, map pin.
