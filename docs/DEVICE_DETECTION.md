# Detecção inteligente de dispositivo e estratégia de reprodução

## Objetivo

Nunca perguntar ao usuário algo que o sistema consegue detectar. Na primeira execução (e sempre que o conjunto de dispositivos pareados mudar), o app determina automaticamente a melhor estratégia de reprodução.

## Modelo de dados

```dart
enum PlaybackStrategy {
  direct,      // Cenário A: relógio -> caixa Bluetooth, sem celular
  relay,       // Cenário B: relógio -> celular -> caixa Bluetooth
  phoneOnly,   // sem relógio compatível pareado; celular dispara tudo
}

class DeviceCapabilityProfile {
  final String manufacturer;
  final String model;
  final String osFamily;      // "wearos" | "watchos" | "garminOs" | "android" | "ios"
  final String osVersion;
  final bool hasBluetoothClassicAudio; // A2DP source capability
  final bool hasBleAudioSupport;       // LE Audio (Bluetooth 5.2+)
  final Set<AudioCodec> supportedCodecs; // sbc, aac, aptx, aptxHd, lc3
  final bool canPlayArbitraryLocalAudio; // API permite tocar arquivo local
  final bool hasPersistentCompanionChannel; // Data Layer / WatchConnectivity disponível
  final int estimatedLatencyMs;
}
```

## Algoritmo (executado no app mobile, orquestrando a sonda do watch)

1. **Descoberta de smartwatch pareado**
   - Wear OS: `Wearable.getCapabilityClient()` + `NodeClient` para listar nós conectados e capacidades anunciadas pelo companion app do relógio.
   - watchOS: `WCSession.isPaired`, `isWatchAppInstalled`, `isReachable`.
   - Garmin: Connect IQ Mobile SDK `DeviceManager` lista dispositivos Garmin pareados via Garmin Connect Mobile.
   - Se nenhum relógio compatível → `PlaybackStrategy.phoneOnly`, pula para o passo 4.

2. **Sonda de capacidades do relógio** (`GET_CAPABILITIES` — comando leve enviado ao companion app do watch, resposta em < 200 ms)
   - O companion app do relógio responde com seu próprio `DeviceCapabilityProfile`, preenchido usando APIs nativas:
     - Wear OS: `BluetoothAdapter.getProfileProxy(A2DP)` + verificação se o `BluetoothA2dp` reporta um dispositivo conectado diretamente pelo relógio (não pelo celular); `PackageManager.hasSystemFeature(FEATURE_AUDIO_OUTPUT)`.
     - watchOS: `AVAudioSession.currentRoute` e checagem de `outputsUsingBluetoothLE`/Classic quando pareado diretamente à caixa; watchOS ≥ 9 em Apple Watch Ultra/Series 8+ com áudio Bluetooth direto reporta `hasBluetoothClassicAudio = true`.
     - Garmin: capacidade consultada por tabela estática de modelos (`garmin_capability_table.json`, mantida em `apps/garmin/resources`) já que o SDK não expõe introspecção de áudio de terceiros na maioria dos dispositivos.

3. **Decisão de estratégia**
   ```
   se watch.hasBluetoothClassicAudio ou watch.hasBleAudioSupport:
       se watch.canPlayArbitraryLocalAudio:
           estrategia = DIRECT
       senao:
           estrategia = RELAY   # rádio existe mas SO não expõe API de áudio arbitrário
   senao:
       estrategia = RELAY se watch.hasPersistentCompanionChannel
       senao: PHONE_ONLY  # relógio não tem canal utilizável; app funciona só no celular
   ```

4. **Verificação da caixa Bluetooth**
   - Celular varre dispositivos pareados com o perfil A2DP ativo (`BluetoothAdapter.getBondedDevices()` filtrado por `BluetoothClass.Device.AUDIO_VIDEO_*` no Android; `AVAudioSession.currentRoute.outputs` no iOS).
   - Se nenhuma caixa pareada, o app usa o alto-falante do próprio dispositivo (celular ou relógio) como saída padrão e oferece o assistente de pareamento (§ abaixo) sem bloquear o uso.

5. **Persistência e reavaliação**
   - Resultado salvo em `SharedPreferences`/`UserDefaults` local **e** sincronizado como atributo do dispositivo em `users/{uid}/devices/{deviceId}` no Firestore (para analytics e suporte).
   - Reavaliado automaticamente em: boot do app, evento de pareamento/despareamento Bluetooth do SO, troca de relógio pareado.
   - Nunca reavaliado de forma síncrona no caminho de reprodução (a decisão já está pronta antes do usuário tocar em um botão).

## Assistente de configuração (primeira execução)

Tela guiada "Vamos configurar seu equipamento":

1. Detecta automaticamente relógio, celular e caixa Bluetooth (passos 1–4 acima), mostrando checkmarks ao vivo — nenhuma pergunta é feita se a resposta é detectável.
2. Se a caixa Bluetooth não estiver pareada: abre as configurações Bluetooth do sistema com deep link (`android.settings.BLUETOOTH_SETTINGS` / `App-Prefs:Bluetooth`) e aguarda o evento de pareamento.
3. Se o relógio suportado não tiver o companion app instalado: mostra instrução + QR/link para a loja de apps do relógio (Play Store para Wear OS/Galaxy Store, App Store para watchOS, Connect IQ Store para Garmin).
4. Ao final, mostra um resumo não técnico: *"Prontinho! Seu Galaxy Watch vai tocar direto na sua caixa JBL."* ou *"Seu Apple Watch vai avisar seu iPhone, que toca na caixa."*

## Tabela de compatibilidade (referência inicial, expansível via `garmin_capability_table.json` / `wearos_capability_table.json`)

| Fabricante | Modelo (exemplos) | Estratégia padrão |
|---|---|---|
| Samsung Galaxy Watch 4/5/6/7 (Wear OS) | Bluetooth Classic A2DP nativo | `DIRECT` |
| Google Pixel Watch 1/2/3 | Bluetooth Classic A2DP nativo | `DIRECT` |
| Apple Watch Series 8+/Ultra (watchOS 9+) | Áudio Bluetooth direto suportado | `DIRECT` |
| Apple Watch SE / Series ≤ 7 | Sem áudio direto confiável | `RELAY` |
| Wear OS genérico sem A2DP exposto | — | `RELAY` |
| Garmin (Forerunner, Fenix, Venu, etc.) | Sem API de áudio de terceiros | `RELAY` |
| Nenhum relógio pareado | — | `PHONE_ONLY` |
