# Vai Márcia — watchOS

SwiftUI companion app, paired with an iOS companion app via `WatchConnectivity`. See
`docs/ARCHITECTURE.md` and `docs/DEVICE_DETECTION.md` at the repo root for the cross-platform
design this app implements.

## About `VaiMarciaWatch.xcodeproj`

A hand-authored `.xcodeproj` (an extremely fragile, mostly-binary pbxproj format) cannot be
reliably produced outside of Xcode itself. Instead, this directory ships a
[XcodeGen](https://github.com/yonaskolb/XcodeGen) spec, `project.yml`, describing the
`VaiMarciaWatchApp` target, its Info.plist entries, and build settings. To generate the real
project:

```sh
brew install xcodegen   # if not already installed
cd apps/watchos
xcodegen generate       # produces VaiMarciaWatch.xcodeproj
open VaiMarciaWatch.xcodeproj
```

This is the standard pragmatic approach for checking in an Xcode project's *source of truth*
without shipping a binary artifact that drifts from the plist source or merges badly in git.

## Structure

- `Domain/` — pure Swift structs/enums (`AudioClip`, `Category`, `PlaybackStrategy`,
  `DeviceCapabilityProfile`). No platform SDK imports (Foundation only).
- `Data/Local/` — `AudioCacheManager` (cached `.m4a` files under `Documents/AudioCache`) and
  `CatalogStore` (JSON-file-backed catalog persistence — see note below on why not SwiftData).
- `Data/Companion/` — `WatchConnectivityManager` wraps `WCSession`: `sendPlayCommand` (with
  `transferUserInfo` fallback when the phone isn't immediately reachable), session activation,
  and receiving catalog syncs pushed from the phone.
- `Playback/` — `DirectPlaybackEngine` (`AVAudioPlayer`, `.playback` category, Scenario A),
  `RelayPlaybackDispatcher` (Scenario B, delegates to `WatchConnectivityManager`),
  `PlaybackStrategyResolver` (implements the decision algorithm from
  `docs/DEVICE_DETECTION.md`, including the static Series 8+/Ultra model-identifier table
  used to infer direct-Bluetooth-audio hardware since watchOS has no runtime capability API
  for it), and `PlaybackController` as the single facade the UI calls.
- `Presentation/` — `VaiMarciaWatchApp` (`@main` entry), `GameModeView` (big-button grid),
  `FirstRunSetupView`, and `Theme.swift` with placeholder TogPlay brand colors.

## Why JSON file storage instead of SwiftData

`project.yml` targets watchOS 9.0 (to include Series 4+ devices, which default to `RELAY`
mode per the compatibility table) but SwiftData requires watchOS 10+. `CatalogStore` uses a
plain JSON file under `Documents/` instead, keeping the deployment floor low without giving
up structured local persistence.

## What's implemented vs scaffold

Implemented (real, idiomatic code, not compiled in this environment):
- Full domain model, WCSession companion wrapper with reachability fallback, AVAudioPlayer
  direct-playback engine, relay dispatcher, strategy resolver following the documented
  algorithm (including the static model-identifier allow-list), SwiftUI views for Modo Jogo
  and first-run setup.

Scaffold / TODO:
- `GameModeView.onCategoryTapped` picks a placeholder `"\(category.id)_default"` audioId
  instead of a real "pick next clip in category" use case — same seam as the Wear OS app, left
  for the same reason (catalog business rules not specified in the architecture docs).
- LE Audio / LC3 capability detection in `PlaybackStrategyResolver` is stubbed to `false`.
- No cache-eviction policy for `AudioCacheManager` (unbounded growth beyond the starter pack).
- App icon / asset catalog images are not fabricated; final TogPlay brand assets to be
  supplied by design and dropped into the (not yet created) `Assets.xcassets`.
