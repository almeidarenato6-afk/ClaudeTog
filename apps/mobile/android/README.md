# android/ — subconjunto escrito manualmente

Este diretório propositalmente **não** contém um projeto Android Flutter
completo (sem gradlew wrapper jar/scripts, sem `local.properties` gerado,
sem drawable `launch_background.xml`, sem mipmaps `ic_launcher`). Isso é
100% boilerplate que o Flutter regenera de forma determinística.

## O que existe aqui e é real

- `app/src/main/AndroidManifest.xml` — permissões (Bluetooth, notificações,
  microfone, foreground service) e o intent filter de deep link para
  `lojatogplay.com.br`.
- `app/build.gradle`, `build.gradle` — versões de dependências,
  `applicationId`, SDK mínimo/alvo/de compilação.
- `app/src/main/kotlin/br/com/togplay/vaimarcia/MainActivity.kt` — registra
  os dois plugins de platform-channel abaixo.
- `app/src/main/kotlin/br/com/togplay/vaimarcia/BluetoothTransportPlugin.kt`
  e `WatchCompanionPlugin.kt` — **scaffolds**. Os nomes de canal e de
  método batem exatamente com o lado Dart (veja
  `lib/features/bluetooth/data/datasources/bluetooth_platform_datasource.dart`
  e `lib/features/watch_companion/data/datasources/watch_companion_platform_datasource.dart`),
  mas quase todo corpo de método é um `result.notImplemented()` com um
  TODO descrevendo a API real do Android a ser chamada (proxy
  `BluetoothA2dp`, Wear OS `MessageClient`/`CapabilityClient`).
  `openBluetoothSettings` é o único método totalmente funcional (apenas
  um `Intent`).

## Para obter um projeto compilável

```bash
cd apps/mobile
flutter create --platforms=android --org br.com.togplay .
```

Execute isso **antes** do primeiro `flutter run`/`flutter build apk` —
ele preenche `gradlew`, `gradle-wrapper.properties`, `local.properties`,
ícones de launcher e `launch_background.xml` sem tocar nos arquivos
listados acima (o Flutter só cria arquivos ausentes, nunca sobrescreve
os escritos manualmente — faça um diff depois de rodar, só por
precaução).

Depois:

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # gera google-services.json + lib/firebase_options.dart
```

Descomente `apply plugin: 'com.google.gms.google-services'` em
`app/build.gradle` assim que `google-services.json` existir.
