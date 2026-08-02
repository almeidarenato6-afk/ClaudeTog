# Vai Márcia — Garmin Connect IQ

Monkey C companion app. See `docs/ARCHITECTURE.md` and `docs/DEVICE_DETECTION.md` at the
repo root for the cross-platform design this app implements.

## Why RELAY by default

Garmin's Connect IQ SDK does not give third-party (Monkey C) apps an API to play arbitrary
local audio files on virtually any current device — the on-device audio hardware (where it
exists at all, e.g. fēnix 8's speaker) is reserved for system features (calls, voice
assistant) and Garmin-first-party apps, not exposed to Connect IQ apps. Because of this, and
because the SDK also has no runtime call to *ask* "can this device play arbitrary audio", this
app:

1. Never attempts DIRECT (Scenario A) playback — there is no `DirectPlaybackEngine` in this
   app, unlike the Wear OS and watchOS apps.
2. Always operates in RELAY (Scenario B): `Communication/CompanionChannel.mc` wraps
   `Toybox.Communications.transmit()` to send a lightweight `{type, audioId}` payload to the
   paired phone's companion app via the Connect IQ Mobile SDK, and the phone (already caching
   the audio locally) plays it to the paired Bluetooth speaker.
3. Confirms this via a **static capability table**
   (`resources/garmin_capability_table.json`), not runtime introspection, per
   `docs/DEVICE_DETECTION.md` step 2's Garmin guidance — the SDK doesn't expose audio-output
   introspection on most devices, so the table is the source of truth and is checked at
   pairing/capability-probe time by the mobile app's device-detection algorithm (not by this
   watch app itself, which only ever sends RELAY commands).

## Persistent channel rationale

`CompanionChannel` calls `Communications.registerForPhoneAppMessages` once in `initialize()`
and keeps the transmit channel "listening" for the app's lifetime, mirroring the latency
guidance in `docs/ARCHITECTURE.md` §4 — re-registering per tap would reintroduce the
phone-app-bridge negotiation cost the persistent-channel pattern exists to avoid.

## Structure

- `manifest.xml` — Connect IQ app manifest: `Communications` permission, a realistic subset
  of modern touchscreen + button Connect IQ devices (fēnix 7/8, Venu 2/3, Forerunner 955/965,
  vivoactive 5, epix 2), pt-BR + en languages.
- `monkey.jungle` — build config (source/resource paths).
- `resources/strings/strings.xml` — pt-BR button/status labels.
- `resources/drawables/` — no binary icon assets are fabricated here; see
  `PLACEHOLDER.txt` for what design needs to supply and how to wire it once available.
- `resources/garmin_capability_table.json` — the static per-model capability table described
  above. Every entry currently has `canPlayArbitraryLocalAudio: false` and
  `strategy: "RELAY"`; no device in the initial list is DIRECT-capable via Connect IQ today.
- `source/VaiMarciaApp.mc` — `Application.AppBase` entry point.
- `source/Domain/AudioClip.mc` — `AudioClip` and `Category` — plain Monkey C classes/consts,
  no `Toybox.WatchUi`/`Toybox.Communications` imports (kept dependency-free like the other
  platforms' domain layers).
- `source/Communication/CompanionChannel.mc` — the RELAY command channel (see above).
- `source/Views/GameModeView.mc` — `WatchUi.Menu2`-based "Modo Jogo" list (Garmin's UI model
  is button/menu-based on many devices, not a free-form touch grid, so a menu is the
  idiomatic glanceable one-action-per-press equivalent of the big-button grid on other
  platforms) plus `PlaybackStatusView`, a brief status toast since RELAY has no local speaker
  feedback to imply "it's playing" the way DIRECT does.
- `source/Delegates/GameModeDelegate.mc` — `Menu2InputDelegate` wiring menu selection to
  `CompanionChannel.sendPlayCommand`.

## Adding a new device

1. Add the product id to `manifest.xml`'s `<iq:products>`.
2. Add an entry to `resources/garmin_capability_table.json` with real values — default to
   `canPlayArbitraryLocalAudio: false` / `strategy: "RELAY"` unless Garmin has shipped a
   documented Connect IQ audio-output API for that model.
3. If the device's screen shape/resolution needs distinct layout resources, add a
   `<deviceId>.resourcePath` line in `monkey.jungle`.

## What's implemented vs scaffold

Implemented: manifest, build config, strings, capability table, domain model, RELAY
companion channel with transmit/ack handling, Menu2 UI + status feedback, selection delegate.

Scaffold / TODO:
- `GameModeDelegate.onSelect` sends a placeholder `categoryId + "_default"` audioId instead
  of resolving a specific clip within the category — same seam as the Wear OS/watchOS apps.
- No favorites-toggle UI (Favoritos category is listed like any other; toggling a favorite is
  a phone-side action per the architecture).
- No app icon PNGs (see `resources/drawables/PLACEHOLDER.txt`).
- No unit tests (Connect IQ's test harness requires the SDK's simulator, unavailable here).
