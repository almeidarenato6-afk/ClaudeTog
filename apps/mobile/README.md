# Vai Márcia — App Mobile (Flutter)

Beach Tennis motivational-audio soundboard, TogPlay. Tap a button, hear
"Vai Márcia!" (or one of ~90 other clips) on your Bluetooth speaker in
under 150ms — from the phone directly, or relayed from a paired
smartwatch. See [`../../docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)
and [`../../docs/DEVICE_DETECTION.md`](../../docs/DEVICE_DETECTION.md) for
the full system design this app implements.

## Setup

```bash
cd apps/mobile

# 1. Regenerate the platform folders' boilerplate (gradlew, Podfile, etc.)
#    without touching the hand-authored files — see android/README.md and
#    ios/README.md for exactly what's real vs. regenerated.
flutter create --platforms=android,ios --org br.com.togplay .

# 2. Firebase — lib/firebase_options.dart is a deliberately-broken
#    placeholder (see the comment at the top of that file). Replace it:
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Install packages
flutter pub get

# 4. Generate code (Freezed/json_serializable models, Drift tables,
#    injectable DI registration, Riverpod codegen)
dart run build_runner build --delete-conflicting-outputs

# 5. Run
flutter run
```

Re-run step 4 after touching any `@JsonSerializable`, `@DriftDatabase`,
`@injectable`/`@lazySingleton`, or `@riverpod` annotation — those all
depend on generated `*.g.dart`/`*.freezed.dart`/`injection.config.dart`
files that are not checked in (standard practice for generated code).

## Architecture

Clean Architecture, feature-first. Each `lib/features/<name>/` is
vertically independent with its own `domain/` (entities, abstract
repositories, use cases — zero Flutter/Firebase imports, unit-testable in
isolation), `data/` (models, local/remote datasources, repository
implementations), and `presentation/` (Riverpod providers/controllers,
widgets, pages). Cross-feature communication goes through `domain`
contracts, never `presentation` → `presentation`.

State management: `flutter_riverpod` (providers colocated in each
feature's `presentation/providers/`). DI: `get_it` + `injectable`
(`lib/core/di/injection.dart`; annotate a class `@injectable` or
`@LazySingleton(as: SomeAbstractType)` and it's wired automatically by
codegen — see step 4 above).

## What's fully implemented (real, would compile against the declared deps)

- **audio_playback** — pooled/preloaded `just_audio` players
  (`AudioPlayerPool`), Drift-backed local cache, Firestore/Storage remote
  datasource, offline-first repository, `BigButtonGrid` UI.
- **categories, favorites** — full domain/data/presentation, Firestore +
  Drift-backed, offline-first fallback to a seeded default category list.
- **device_pairing** — `DecidePlaybackStrategyUseCase` is the algorithm
  from `docs/DEVICE_DETECTION.md` transcribed verbatim (and unit tested);
  `RunCapabilityProbeUseCase` orchestrates it; "Vamos configurar seu
  equipamento" wizard UI.
- **recording** — `record`-package-backed capture,
  `AudioProcessingPipeline` seam with `PassthroughStage` wired in today.
- **auth** — Google/Apple/email/anonymous via Firebase Auth, with
  anonymous-account upgrade (`linkAnonymousToEmail`).
- **store** — `ExternalLinkStoreRepository` (opens
  `www.lojatogplay.com.br` via `url_launcher`), persistent banner, store
  screen. `Product`/`Promotion`/`Cart` domain entities modeled but unused,
  per spec, for a future e-commerce implementation.
- **notifications** — FCM + `flutter_local_notifications` foreground
  display, Firestore-backed in-app notification list.
- **analytics** — `AnalyticsService` abstract + `FirebaseAnalyticsService`,
  wired into playback/favorite events.

## What's a scaffold/stub (native platform-channel work required)

Flutter has no first-party plugin that gives the level of control this
product needs over Bluetooth Classic A2DP (persistent "warm" route,
paired-device brand introspection) or the Wear OS Data Layer /
WatchConnectivity companion channel. These are **not implementable in
pure Dart** — they need real native code, which is scaffolded but not
implemented:

- `lib/features/bluetooth/` — `BluetoothTransport` interface is complete
  and tested at the Dart boundary; `BluetoothPlatformDataSource` calls a
  method/event channel whose native side
  (`android/.../BluetoothTransportPlugin.kt`,
  `ios/Runner/BluetoothTransportPlugin.swift`) is a documented TODO stub
  per method (`android/README.md` and `ios/README.md` explain exactly
  what's missing and why, including an iOS platform limitation: no public
  API lists *all* paired Bluetooth Classic devices, only the active
  route).
- `lib/features/watch_companion/` — same pattern for
  `WatchCompanionPlugin.kt`/`.swift` (Wear OS `MessageClient`/
  `CapabilityClient` on Android, `WCSession` on iOS).
- `lib/features/device_pairing/data/datasources/device_capability_probe_datasource.dart`
  depends on the watch_companion channel above for the actual
  `GET_CAPABILITIES` probe; until the native side exists it safely
  degrades to `PlaybackStrategy.phoneOnly` rather than throwing.

Every stub method either throws `MissingPluginException` (caught and
treated as "no data") in Dart, or `result.notImplemented()` /
`FlutterMethodNotImplemented` on the native side — the app never crashes
because of these gaps, it just can't yet do direct/relay playback for
real until the native plugins are filled in.

`lib/firebase_options.dart` is a placeholder with `REPLACE_ME_*` values —
see the file's header comment — that intentionally throws for platforms
it wasn't generated for, so a build never silently talks to a nonexistent
Firebase project.

## AI extension seam (not implemented, by design)

`lib/features/recording/domain/pipeline/audio_processing_pipeline.dart`
defines `AudioProcessingStage` and wires only `PassthroughStage` in today.
`NoiseReductionStage`, `VoiceEnhancementStage`, `PhraseSegmentationStage`,
`AutoCategorizationStage` are documented as abstract interfaces with zero
implementation — future work plugs in without touching
`RecordingRepositoryImpl`, the recording UI, or the upload path.

## Tests

```bash
flutter test
```

- `test/device_pairing/decide_playback_strategy_usecase_test.dart` —
  exhaustively covers every branch of the DEVICE_DETECTION.md decision
  table.
- `test/audio_playback/audio_repository_impl_test.dart` — play-from-cache
  vs. download-then-play, preload-only-missing-clips, failure mapping.
- `test/favorites/toggle_favorite_usecase_test.dart` — toggle on/off,
  local-authoritative-even-if-remote-sync-fails, failure mapping.

All three use `mocktail` against the `domain`-facing interfaces, not
Firebase/Drift/just_audio directly.

## Brand palette placeholder

`lib/core/theme/app_colors.dart` uses a placeholder palette (coral/orange
primary, deep navy secondary) — no official TogPlay brand kit exists yet.
Every constant is commented `TOGPLAY_BRAND_PLACEHOLDER`; grep for that
string when the real brand guideline lands.
