# android/ — hand-authored subset

This directory intentionally does **not** contain a full Flutter Android
project (no Gradle wrapper jar/scripts, no generated `local.properties`,
no `launch_background.xml` drawable, no `ic_launcher` mipmaps). Those are
100% boilerplate that Flutter regenerates deterministically.

## What's here and real

- `app/src/main/AndroidManifest.xml` — permissions (Bluetooth, notifications,
  microphone, foreground service) and the deep-link intent filter for
  `lojatogplay.com.br`.
- `app/build.gradle`, `build.gradle` — dependency versions, `applicationId`,
  min/target/compile SDK.
- `app/src/main/kotlin/br/com/togplay/vaimarcia/MainActivity.kt` — registers
  the two platform-channel plugins below.
- `app/src/main/kotlin/br/com/togplay/vaimarcia/BluetoothTransportPlugin.kt`
  and `WatchCompanionPlugin.kt` — **scaffolds**. Channel names and method
  names match the Dart side exactly (see
  `lib/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart`
  and `lib/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart`),
  but nearly every method body is a `result.notImplemented()` with a TODO
  describing the real Android API to call (`BluetoothA2dp` proxy,
  Wear OS `MessageClient`/`CapabilityClient`). `openBluetoothSettings` is
  the one fully working method (just an `Intent`).

## To get a buildable project

```bash
cd apps/mobile
flutter create --platforms=android --org br.com.togplay .
```

Run this **before** your first `flutter run`/`flutter build apk` — it
fills in `gradlew`, `gradle-wrapper.properties`, `local.properties`,
launcher icons, and `launch_background.xml` without touching the files
listed above (Flutter only creates missing files, never overwrites
hand-authored ones — diff after running just in case).

Then:

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # generates google-services.json + lib/firebase_options.dart
```

Uncomment `apply plugin: 'com.google.gms.google-services'` in
`app/build.gradle` once `google-services.json` exists.
