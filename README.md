# RoomFinder LR

A verified house and room rental finder for Liberia. One Flutter codebase builds the **Android app** and the **website**. Data lives in **Firebase** (free Spark plan), photos on **Cloudinary** (free plan), and **GitHub Actions** builds everything on every push.

"RoomFinder LR" is a working name — change `appName` in `lib/config.dart`.

## What works in this first version

- Browse without an account: search by community and type, filter by budget, amenities and "verified only", sort by recently confirmed or cheapest
- Listing page: photos, price, advance months, amenities, landmark, verified badge, "confirmed free X days ago", safety tips, share link
- Sign in with Google or email/password; Call and WhatsApp buttons (sign-in needed to see the number)
- Save places; report a listing (taken, fake, wrong price, scam)
- Landlords and agents: add a place (3–8 photos), edit (goes back to review), "Still free", "Mark taken", delete
- Places not confirmed for 14 days drop out of search automatically
- Admin tab: approve, approve + verified, reject with a reason, handle reports, hide listings, ban owners

## One-time setup (about 30 minutes)

### 1. GitHub repository
1. Create a new **public** repo (for example `roomfinder`) and upload everything in this folder.
2. Repo **Settings → Pages → Build and deployment → Source: GitHub Actions**.

### 2. Firebase project (free)
1. At console.firebase.google.com create a project (you can't reuse the CarryMe one unless you want both apps to share data — don't).
2. **Build → Authentication → Sign-in method**: turn on **Email/Password** and **Google**.
3. **Authentication → Settings → Authorized domains**: add `YOUR-GITHUB-NAME.github.io`.
4. **Build → Firestore Database → Create database** (production mode, choose a nearby region such as `europe-west`).
5. **Project settings → Your apps**: add a **Web app** and an **Android app** (package name `lr.roomfinder.roomfinder`). You do *not* need to download `google-services.json`.
6. From the web app's config, note: `apiKey`, `appId` (web), `messagingSenderId`, `projectId`, `authDomain`. From the Android app, note its `appId` (starts with `1:...:android:`).

### 3. Firestore rules and indexes
Easiest without installing anything:
- **Firestore → Rules**: paste the whole of `firestore.rules`, then **Publish**.
- **Indexes**: create the 7 composite indexes listed in `firestore.indexes.json` (Firestore → Indexes → Composite → Create). Or, if you have Node.js on a computer: `npm i -g firebase-tools`, `firebase login`, `firebase deploy --only firestore --project YOUR_PROJECT_ID` from this folder.
- Tip: if you skip an index, the app shows "The database needs an index" and the browser console prints a direct link that creates it in one click.

### 4. Cloudinary (photos, free)
1. Sign up at cloudinary.com and note your **Cloud name**.
2. **Settings → Upload → Upload presets → Add**: Signing mode **Unsigned**, folder `listings`, allowed formats `jpg,png,webp,heic`, max file size about 5 MB. Save and note the preset name.

### 5. GitHub secrets
Repo **Settings → Secrets and variables → Actions → New repository secret**, one each:

| Secret | Value |
| --- | --- |
| `FIREBASE_API_KEY` | apiKey |
| `FIREBASE_APP_ID_WEB` | web appId |
| `FIREBASE_APP_ID_ANDROID` | Android appId |
| `FIREBASE_SENDER_ID` | messagingSenderId |
| `FIREBASE_PROJECT_ID` | projectId |
| `FIREBASE_AUTH_DOMAIN` | authDomain (optional) |
| `CLOUDINARY_CLOUD` | Cloudinary cloud name |
| `CLOUDINARY_PRESET` | unsigned preset name |

### 6. Build
Push to `main` (or **Actions → Build app → Run workflow**). When it finishes:
- **APK**: open the run → **Artifacts → roomfinder-apk** → unzip → install on the phone.
- **Website**: `https://YOUR-GITHUB-NAME.github.io/REPO-NAME/`

### 7. Make yourself admin
Sign in once in the app, then in **Firestore → users → (your document)** change `role` to `admin`. Reopen the app: the **Admin** tab appears.

## Good to know

- **Google sign-in on Android** needs the app's signing key SHA-1 added in Firebase (Project settings → Android app → Add fingerprint). CI currently signs with a new temporary debug key on each build, so for Google sign-in on Android add a fixed release keystore (same method as CarryMe's `ANDROID_KEYSTORE_BASE64` secret). Email/password and Google sign-in on the website work straight away.
- `android/` and `web/` are generated in CI by `flutter create`. When you want a custom app icon, app label or release signing, run `flutter create --platforms=android,web --org lr.roomfinder .` once on a computer, adjust, and commit those folders (remove them from `.gitignore`).
- The LRD→USD rate used for budget filters is `lrdPerUsd` in `lib/config.dart` (default 190). Update it when the rate moves.
- Communities and listing types are plain lists in `lib/data/liberia.dart`.
- Contact numbers are stored in `listingContacts/{listingId}`, apart from the listing, so the future "pay to unlock" step only needs a change to that one rule.
- The unsigned Cloudinary preset lets anyone who finds the preset name upload images. Keep the folder and size limits on; switch to signed uploads once there is a small server.

## Project layout

```
lib/
  main.dart                 app, routes (share links: /#/listing?id=...), bottom tabs
  config.dart               settings from --dart-define (GitHub secrets)
  data/liberia.dart         communities, types, amenities, report reasons
  models/listing.dart       Listing, AppUser, ListingContact, Report
  services/session.dart     sign-in and the user's profile
  services/listing_service.dart  all Firestore reads and writes
  services/photo_service.dart    pick, shrink and upload photos
  screens/                  search, listing page, add/edit, my places, saved, account, admin, login
  widgets/common.dart       cards, badges, empty states, error messages
firestore.rules             security rules
firestore.indexes.json      composite indexes
.github/workflows/build.yml APK + website build and GitHub Pages deploy
```
