# Vai Márcia — Backend (Firebase)

Firestore + Cloud Storage + Cloud Functions (TypeScript) + Firebase Auth backend for the
Vai Márcia (TogPlay) soundboard app. See [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)
for full system context.

## Layout

```
backend/
├── firebase.json / .firebaserc      # project config (fill in the real project ID)
├── firestore.rules / storage.rules  # security rules — see "Security model" below
├── firestore.indexes.json           # composite indexes for catalog queries
├── functions/                       # Cloud Functions (TypeScript, firebase-functions v2)
│   └── src/
│       ├── config/                  # Admin SDK init, env/region config
│       ├── domain/                  # Firestore schema as TS types (source of truth)
│       ├── repositories/            # one class per collection, all Firestore access goes through these
│       ├── api/admin/               # admin-panel callables (custom-claim-gated)
│       ├── api/catalog/             # public catalog callables
│       ├── api/client/              # mobile/watch callables
│       ├── triggers/                # Firestore/Auth/Scheduler triggers
│       └── notifications/           # FCM sending helper
└── seed/                            # one-off script to populate starter catalog data
```

## Setup

```bash
npm install -g firebase-tools
firebase login

cd backend
firebase use --add          # pick/alias your Firebase project, replacing the TODO in .firebaserc

cd functions
npm install
npm run build
```

## Local development

```bash
cd backend
firebase emulators:start --only functions,firestore,storage,auth
```

The emulator UI runs at `http://localhost:4000`.

## Deploy

```bash
cd backend
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

Hosting (for the admin panel build output) deploys separately once `admin/` has a build
step producing `admin/dist`:

```bash
firebase deploy --only hosting
```

## Admin roles (custom claims)

Roles (`admin`, `content_manager`, `viewer`) live **only** as Firebase Auth custom claims —
never mirrored into a Firestore document a client could write to. There is no
Firestore-console way to see "who is an admin"; check custom claims via the Firebase console
(Authentication → user → "Custom claims" is not shown there — use the Admin SDK/CLI) or:

```js
// one-off script, run with GOOGLE_APPLICATION_CREDENTIALS set to a service account key
const admin = require("firebase-admin");
admin.initializeApp();
await admin.auth().setCustomUserClaims("<uid-of-first-admin>", { role: "admin" });
```

Every subsequent admin/content_manager/viewer grant can go through the `setUserRole`
callable (admin-role-only) once that first admin exists — see
`functions/src/api/admin/auth.ts`.

Clients must force-refresh their ID token after a role change
(`getIdToken(true)` / `getIdTokenResult(true)`) to pick up new claims.

## Seeding starter content

```bash
cd backend/seed
npm install
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
STORAGE_BUCKET=<your-project-id>.appspot.com \
npx ts-node seed.ts
```

Writes 9 categories and 15 sample `AudioClip` docs (Portuguese motivational phrases —
"Vai Márcia!", "Bora!", "Acredita!", etc.). This only creates Firestore documents; it does
**not** upload actual `.m4a` audio files. Upload real masters to
`catalog/audios/{audioId}/master.m4a` in Cloud Storage (via the admin panel once built, or
`gsutil cp`) before the seeded `audioUrl`s will resolve.

## Security model

- **Catalog** (`categories`, `audios`): public read, write requires the `admin` or
  `content_manager` custom claim.
- **Users** (`users/{uid}` and everything under it): owner-only. `favorites` is written
  directly by the client (see `functions/src/api/client/favorites.ts` for why); `devices` is
  written only via the `registerDevice` callable; `recordings` is private, owner read/write.
- **Analytics** (`analytics_events`, `analytics_daily`): no direct client access at all —
  ingestion is via the `recordAnalyticsEvent` callable, rollups are read-only for admin roles.
- **Promotions**: public read, `admin`-only write.
- Enforcement is in `firestore.rules`/`storage.rules` (the actual authority) *and* re-checked
  in every admin callable via `requireRole`/`requireContentManager`/`requireAdmin` — never
  trust a client-side check alone.

## What's implemented

- Firestore/Storage security rules (owner-only user data, public-read/admin-write catalog,
  function-only analytics).
- Domain types for every collection (`functions/src/domain/`).
- Repository layer for Firestore access (`functions/src/repositories/`).
- Admin callables: `createAudio`, `updateAudio`, `deleteAudio` (soft delete), `createCategory`,
  `updateCategory`, `listAnalyticsSummary`, `sendNotification`, `createPromotion`,
  `setUserRole`.
- Public callable: `getStarterPack` (categories + featured audios for first-run offline use).
- Client callables: `registerDevice`, `recordAnalyticsEvent` (batched ingestion).
- Triggers: `onAudioCreate` (defaults safety net), `onUserCreate` (profile bootstrap),
  `onFavoriteWrite` (keeps `AudioClip.favoriteCount` in sync), `aggregateDailyAnalytics`
  (scheduled daily rollup, also syncs `AudioClip.playCount`).
- Seed script with 9 categories and 15 sample audio clips.

## Explicit TODOs / not implemented

- **`deleteCategory`**: categories are expected to be long-lived; deactivate via
  `updateCategory({ isActive: false })` instead. Add a dedicated callable if the admin panel
  needs an explicit "archive category" affordance beyond that.
- **BigQuery export for analytics**: `analytics_events` is Firestore-only today. Per
  ARCHITECTURE.md §11, high-volume analytics should stream through Pub/Sub into BigQuery
  instead — noted in code (`analyticsEvents.ts`, `aggregateDailyAnalytics.ts`) but not built.
- **AI audio processing pipeline**: `Recording.status` includes a `processing` state as an
  extension point (mirrors the client's `AudioProcessingPipeline` stages in
  ARCHITECTURE.md §8), but no server-side processing runs today — recordings stay
  `uploaded`/`ready` only.
- **E-commerce**: `Promotion` has a commented-out extension block
  (`couponCode`, `discountPercent`, `cashbackPercent`, `minPurchaseValue`,
  `loyaltyPointsMultiplier`) for a future in-app store. Today promotions are just banners
  linking out to https://www.lojatogplay.com.br.
- **Remote Config**: feature flags / store banner params are managed directly in the Firebase
  console today; no Cloud Function manages Remote Config parameters programmatically.
- **`.firebaserc`**: still has a placeholder project alias — replace with the real project ID
  via `firebase use --add`.
