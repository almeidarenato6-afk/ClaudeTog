# ios/ — hand-authored subset

Like `android/`, this is not a full Flutter iOS project — no `.xcodeproj`,
no `Podfile.lock`, no `Assets.xcassets`, no `Base.lproj` storyboards. Those
are boilerplate Xcode/Flutter generate deterministically.

## What's here and real

- `Runner/Info.plist` — Bluetooth (`NSBluetoothAlwaysUsageDescription`,
  `NSBluetoothPeripheralUsageDescription`), microphone
  (`NSMicrophoneUsageDescription`), background audio mode, and the
  `vaimarcia://` URL scheme.
- `Runner/AppDelegate.swift` — registers the two platform-channel plugins
  below alongside Flutter's `GeneratedPluginRegistrant`.
- `Runner/BluetoothTransportPlugin.swift`, `WatchCompanionPlugin.swift` —
  **scaffolds**. Channel/method names match the Dart side exactly (see
  `lib/features/bluetooth/...` and `lib/features/watch_companion/...`),
  but the bodies are `FlutterMethodNotImplemented` TODOs describing the
  real `AVAudioSession` / `WatchConnectivity` (`WCSession`) calls needed.
  `openBluetoothSettings` opens the app's Settings entry (iOS has no
  public deep link straight into Settings > Bluetooth for third-party
  apps).

## Known iOS platform limitation (documented, not a bug)

Unlike Android's `BluetoothAdapter.getBondedDevices()`, iOS has **no**
public API to list all paired Bluetooth Classic devices — only the
currently active `AVAudioSession` output route. `listPairedAudioDevices`
will realistically return at most one device. This is called out again in
the Swift TODO and should be surfaced to product/design as a platform
constraint, not "fixed" with a private API (App Store rejection risk).

## To get a buildable project

```bash
cd apps/mobile
flutter create --platforms=ios --org br.com.togplay .
cd ios && pod install
```

Then:

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # generates ios/Runner/GoogleService-Info.plist + lib/firebase_options.dart
```
