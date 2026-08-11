# ios/ — subconjunto escrito manualmente

Assim como `android/`, este não é um projeto iOS Flutter completo — sem
`.xcodeproj`, sem `Podfile.lock`, sem `Assets.xcassets`, sem storyboards
`Base.lproj`. Isso é boilerplate que Xcode/Flutter geram de forma
determinística.

## O que existe aqui e é real

- `Runner/Info.plist` — Bluetooth (`NSBluetoothAlwaysUsageDescription`,
  `NSBluetoothPeripheralUsageDescription`), microfone
  (`NSMicrophoneUsageDescription`), modo de áudio em segundo plano, e o
  esquema de URL `vaimarcia://`.
- `Runner/AppDelegate.swift` — registra os dois plugins de
  platform-channel abaixo junto com o `GeneratedPluginRegistrant` do
  Flutter.
- `Runner/BluetoothTransportPlugin.swift`, `WatchCompanionPlugin.swift` —
  **scaffolds**. Os nomes de canal/método batem exatamente com o lado
  Dart (veja `lib/features/bluetooth/...` e
  `lib/features/watch_companion/...`), mas os corpos são TODOs com
  `FlutterMethodNotImplemented` descrevendo as chamadas reais de
  `AVAudioSession` / `WatchConnectivity` (`WCSession`) necessárias.
  `openBluetoothSettings` abre a entrada do app nos Ajustes (o iOS não
  tem um deep link público direto para Ajustes > Bluetooth para apps de
  terceiros).

## Limitação conhecida da plataforma iOS (documentada, não é um bug)

Diferente do `BluetoothAdapter.getBondedDevices()` do Android, o iOS
**não** tem API pública para listar todos os dispositivos Bluetooth
Classic pareados — apenas a rota de saída ativa no momento do
`AVAudioSession`. `listPairedAudioDevices` realisticamente retornará no
máximo um dispositivo. Isso é apontado novamente no TODO do Swift e deve
ser levado ao produto/design como uma restrição de plataforma, e não
"corrigido" com uma API privada (risco de rejeição na App Store).

## Para obter um projeto compilável

```bash
cd apps/mobile
flutter create --platforms=ios --org br.com.togplay .
cd ios && pod install
```

Depois:

```bash
dart pub global activate flutterfire_cli
flutterfire configure   # gera ios/Runner/GoogleService-Info.plist + lib/firebase_options.dart
```
