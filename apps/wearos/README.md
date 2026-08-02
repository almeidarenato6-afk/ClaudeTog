# Vai Márcia — Wear OS

Kotlin + Jetpack Compose (Wear Compose) companion app. See `docs/ARCHITECTURE.md` and
`docs/DEVICE_DETECTION.md` at the repo root for the cross-platform design this app implements.

## Structure

- `domain/` — pure Kotlin entities (`AudioClip`, `Category`, `PlaybackStrategy`,
  `DeviceCapabilityProfile`). No Android imports; mirrors the mobile app's domain concepts.
- `data/local/` — Room DB (`VaiMarciaDatabase`) holding the starter pack + synced catalog
  subset, plus `AudioCacheStore` for the actual cached audio files on disk.
- `data/companion/` — `WearCompanionClient` wraps the Wearable Data Layer API
  (`MessageClient`/`DataClient`/`CapabilityClient`) for sending play commands (Scenario B)
  and receiving catalog syncs pushed from the phone. `WearCompanionListenerService` receives
  background pushes so the cache stays warm without the activity being open.
- `playback/` — `DirectPlaybackEngine` (Media3/ExoPlayer, Scenario A), `RelayPlaybackDispatcher`
  (Scenario B, delegates to `WearCompanionClient`), `PlaybackStrategyResolver` (implements the
  decision algorithm from `docs/DEVICE_DETECTION.md`), and `PlaybackController` as the single
  facade the UI calls.
- `presentation/` — `MainActivity`, `GameModeScreen` ("Modo Jogo" big-button grid),
  `FirstRunSetupScreen`, and a Wear Compose `theme/` with placeholder TogPlay brand colors.
- `di/` — Hilt modules (`DataModule` provides the Room database; everything else uses
  constructor injection directly).

## What's implemented vs scaffold

Implemented (real, idiomatic code, not runnable/compiled in this environment):
- Full domain model, Room schema, DataLayer companion wrapper, ExoPlayer direct-playback
  engine, relay dispatcher, strategy resolver following the documented algorithm, Compose UI
  for Modo Jogo and first-run setup, Hilt wiring.

Scaffold / TODO (explicitly out of scope per task, left as clear seams):
- `GameModeViewModel.onCategoryTapped` picks a placeholder `"${category.id}_default"` audioId
  instead of a real "pick next clip in category" use case (favorites rotation, most-recent,
  etc.) — that logic belongs in a `domain` use case backed by `AudioClipDao`, same shape as
  the mobile app's equivalent, and was left as a one-line seam to avoid inventing catalog
  business rules not specified in the architecture docs.
- LE Audio (Bluetooth 5.2+) capability detection in `PlaybackStrategyResolver` is stubbed to
  `false` — requires `BluetoothLeAudioCodecConfig` (API 33+) and device-specific handling not
  detailed in `docs/DEVICE_DETECTION.md`.
- Launcher icon is a placeholder vector; final TogPlay brand mark to be supplied by design.
- No tiles/complications (not requested).

## Build

This is a standard Gradle multi-module Android/Wear OS project (`settings.gradle.kts` +
root/app `build.gradle.kts`). It cannot be built in this text-only environment; open with
Android Studio (Hedgehog+) with a Wear OS 3+ emulator/device target.
