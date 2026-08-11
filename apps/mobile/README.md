# Vai Márcia — App Mobile (Flutter)

Soundboard de áudio motivacional para Beach Tennis, TogPlay. Toque um botão, ouça
"Vai Márcia!" (ou um dos outros ~90 clipes) na sua caixa de som Bluetooth em
menos de 150ms — direto do celular, ou retransmitido a partir de um
smartwatch pareado. Veja [`../../docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)
e [`../../docs/DEVICE_DETECTION.md`](../../docs/DEVICE_DETECTION.md) para
o design completo do sistema que este app implementa.

## Configuração

```bash
cd apps/mobile

# 1. Regenerar o boilerplate das pastas de plataforma (gradlew, Podfile, etc.)
#    sem tocar nos arquivos escritos manualmente — veja android/README.md e
#    ios/README.md para saber exatamente o que é real vs. regenerado.
flutter create --platforms=android,ios --org br.com.togplay .

# 2. Firebase — lib/firebase_options.dart é um placeholder propositalmente
#    quebrado (veja o comentário no topo desse arquivo). Substitua-o:
dart pub global activate flutterfire_cli
flutterfire configure

# 3. Instalar pacotes
flutter pub get

# 4. Gerar código (modelos Freezed/json_serializable, tabelas Drift,
#    registro de DI do injectable, codegen do Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 5. Executar
flutter run
```

Execute novamente o passo 4 depois de mexer em qualquer anotação
`@JsonSerializable`, `@DriftDatabase`, `@injectable`/`@lazySingleton` ou
`@riverpod` — todas elas dependem de arquivos gerados
`*.g.dart`/`*.freezed.dart`/`injection.config.dart` que não são versionados
(prática padrão para código gerado).

## Arquitetura

Clean Architecture, feature-first. Cada `lib/features/<name>/` é
verticalmente independente, com seu próprio `domain/` (entidades,
repositórios abstratos, casos de uso — zero imports de Flutter/Firebase,
testável isoladamente), `data/` (modelos, datasources locais/remotos,
implementações de repositório) e `presentation/` (providers/controllers
Riverpod, widgets, páginas). A comunicação entre features passa pelos
contratos do `domain`, nunca `presentation` → `presentation`.

Gerenciamento de estado: `flutter_riverpod` (providers colocados no
`presentation/providers/` de cada feature). DI: `get_it` + `injectable`
(`lib/core/di/injection.dart`; anote uma classe com `@injectable` ou
`@LazySingleton(as: SomeAbstractType)` e ela é conectada automaticamente
pelo codegen — veja o passo 4 acima).

## O que está totalmente implementado (real, compilaria contra as deps declaradas)

- **audio_playback** — players `just_audio` com pool/preload
  (`AudioPlayerPool`), cache local baseado em Drift, datasource remoto
  Firestore/Storage, repositório offline-first, UI `BigButtonGrid`.
- **categories, favorites** — domain/data/presentation completos,
  baseados em Firestore + Drift, com fallback offline-first para uma
  lista padrão de categorias pré-carregada.
- **device_pairing** — `DecidePlaybackStrategyUseCase` é o algoritmo de
  `docs/DEVICE_DETECTION.md` transcrito literalmente (e testado
  unitariamente); `RunCapabilityProbeUseCase` o orquestra; UI do
  assistente "Vamos configurar seu equipamento".
- **recording** — captura baseada no pacote `record`, seam
  `AudioProcessingPipeline` com `PassthroughStage` conectado por
  enquanto.
- **auth** — Google/Apple/e-mail/anônimo via Firebase Auth, com upgrade
  de conta anônima (`linkAnonymousToEmail`).
- **store** — `ExternalLinkStoreRepository` (abre
  `www.lojatogplay.com.br` via `url_launcher`), banner persistente, tela
  da loja. Entidades de domínio `Product`/`Promotion`/`Cart` modeladas
  mas não utilizadas, conforme especificação, para uma futura
  implementação de e-commerce.
- **notifications** — FCM + exibição em primeiro plano via
  `flutter_local_notifications`, lista de notificações in-app baseada em
  Firestore.
- **analytics** — `AnalyticsService` abstrato + `FirebaseAnalyticsService`,
  conectado aos eventos de reprodução/favoritos.

## O que é scaffold/stub (requer trabalho nativo via platform-channel)

O Flutter não tem um plugin first-party que dê o nível de controle que
este produto precisa sobre Bluetooth Classic A2DP (rota "quente"
persistente, introspecção de marca do dispositivo pareado) ou sobre o
canal companion Wear OS Data Layer / WatchConnectivity. Isso **não é
implementável em Dart puro** — precisa de código nativo real, que está
com o scaffold pronto mas não implementado:

- `lib/features/bluetooth/` — a interface `BluetoothTransport` está
  completa e testada na fronteira com o Dart; `BluetoothPlatformDataSource`
  chama um method/event channel cujo lado nativo
  (`android/.../BluetoothTransportPlugin.kt`,
  `ios/Runner/BluetoothTransportPlugin.swift`) é um stub documentado com
  TODO por método (`android/README.md` e `ios/README.md` explicam
  exatamente o que falta e por quê, incluindo uma limitação de
  plataforma no iOS: nenhuma API pública lista *todos* os dispositivos
  Bluetooth Classic pareados, apenas a rota ativa).
- `lib/features/watch_companion/` — mesmo padrão para
  `WatchCompanionPlugin.kt`/`.swift` (Wear OS `MessageClient`/
  `CapabilityClient` no Android, `WCSession` no iOS).
- `lib/features/device_pairing/data/datasources/device_capability_probe_datasource.dart`
  depende do canal watch_companion acima para a sondagem real de
  `GET_CAPABILITIES`; até que o lado nativo exista, ela degrada com
  segurança para `PlaybackStrategy.phoneOnly` em vez de lançar exceção.

Todo método stub lança `MissingPluginException` (capturada e tratada
como "sem dados") no Dart, ou `result.notImplemented()` /
`FlutterMethodNotImplemented` no lado nativo — o app nunca quebra por
causa dessas lacunas, apenas ainda não consegue fazer reprodução
direta/relay de verdade até que os plugins nativos sejam preenchidos.

`lib/firebase_options.dart` é um placeholder com valores `REPLACE_ME_*` —
veja o comentário no cabeçalho do arquivo — que lança exceção
propositalmente para plataformas para as quais não foi gerado, de modo
que um build nunca fale silenciosamente com um projeto Firebase
inexistente.

## Seam de extensão para IA (não implementado, por design)

`lib/features/recording/domain/pipeline/audio_processing_pipeline.dart`
define `AudioProcessingStage` e conecta apenas `PassthroughStage` por
enquanto. `NoiseReductionStage`, `VoiceEnhancementStage`,
`PhraseSegmentationStage`, `AutoCategorizationStage` estão documentados
como interfaces abstratas sem implementação — trabalho futuro se encaixa
sem tocar em `RecordingRepositoryImpl`, na UI de gravação, ou no fluxo de
upload.

## Testes

```bash
flutter test
```

- `test/device_pairing/decide_playback_strategy_usecase_test.dart` —
  cobre exaustivamente todos os ramos da tabela de decisão do
  DEVICE_DETECTION.md.
- `test/audio_playback/audio_repository_impl_test.dart` — reprodução a
  partir do cache vs. baixar-e-então-reproduzir, pré-carregamento apenas
  dos clipes faltantes, mapeamento de falhas.
- `test/favorites/toggle_favorite_usecase_test.dart` — alternar
  ativado/desativado, autoridade local mesmo quando a sincronização
  remota falha, mapeamento de falhas.

Os três usam `mocktail` contra as interfaces voltadas ao `domain`, não
diretamente Firebase/Drift/just_audio.

## Placeholder da paleta de marca

`lib/core/theme/app_colors.dart` usa uma paleta placeholder (coral/laranja
primário, azul-marinho profundo secundário) — ainda não existe um kit de
marca oficial da TogPlay. Toda constante tem o comentário
`TOGPLAY_BRAND_PLACEHOLDER`; procure por essa string quando o guia de
marca real chegar.
