# Vai Márcia — Wear OS

App companion em Kotlin + Jetpack Compose (Wear Compose). Veja `docs/ARCHITECTURE.md` e
`docs/DEVICE_DETECTION.md` na raiz do repositório para o design multiplataforma que este app implementa.

## Estrutura

- `domain/` — entidades Kotlin puras (`AudioClip`, `Category`, `PlaybackStrategy`,
  `DeviceCapabilityProfile`). Sem imports do Android; espelha os conceitos de domínio do app mobile.
- `data/local/` — banco Room (`VaiMarciaDatabase`) contendo o pacote inicial + o subconjunto do
  catálogo sincronizado, além do `AudioCacheStore` para os arquivos de áudio efetivamente
  armazenados em cache no disco.
- `data/companion/` — `WearCompanionClient` envolve a Wearable Data Layer API
  (`MessageClient`/`DataClient`/`CapabilityClient`) para enviar comandos de reprodução (Cenário B)
  e receber sincronizações de catálogo enviadas pelo celular. `WearCompanionListenerService` recebe
  envios em segundo plano para manter o cache atualizado sem a necessidade da activity estar aberta.
- `playback/` — `DirectPlaybackEngine` (Media3/ExoPlayer, Cenário A), `RelayPlaybackDispatcher`
  (Cenário B, delega para `WearCompanionClient`), `PlaybackStrategyResolver` (implementa o
  algoritmo de decisão de `docs/DEVICE_DETECTION.md`), e `PlaybackController` como a única
  fachada que a UI chama.
- `presentation/` — `MainActivity`, `GameModeScreen` (grade de botões grandes do "Modo Jogo"),
  `FirstRunSetupScreen`, e um `theme/` em Wear Compose com cores provisórias da marca TogPlay.
- `di/` — módulos Hilt (`DataModule` fornece o banco Room; todo o restante usa
  injeção via construtor diretamente).

## O que está implementado vs. esqueleto

Implementado (código real e idiomático, mas não executável/compilável neste ambiente):
- Modelo de domínio completo, schema do Room, wrapper de companion via DataLayer, engine de
  reprodução direta com ExoPlayer, dispatcher de relay, resolvedor de estratégia seguindo o
  algoritmo documentado, UI em Compose para o Modo Jogo e configuração de primeira execução,
  ligação via Hilt.

Esqueleto / TODO (explicitamente fora de escopo para esta tarefa, deixado como pontos claros de extensão):
- `GameModeViewModel.onCategoryTapped` escolhe um audioId provisório `"${category.id}_default"`
  em vez de um caso de uso real de "escolher o próximo clipe da categoria" (rotação de favoritos,
  mais recente, etc.) — essa lógica pertence a um caso de uso de `domain` apoiado em
  `AudioClipDao`, no mesmo formato do equivalente no app mobile, e foi deixada como um ponto de
  extensão de uma linha para evitar inventar regras de negócio de catálogo não especificadas nos
  documentos de arquitetura.
- A detecção de capacidade LE Audio (Bluetooth 5.2+) em `PlaybackStrategyResolver` está fixada
  em `false` — requer `BluetoothLeAudioCodecConfig` (API 33+) e tratamento específico por
  dispositivo não detalhado em `docs/DEVICE_DETECTION.md`.
- O ícone do launcher é um vetor provisório; a marca final da TogPlay será fornecida pelo design.
- Sem tiles/complications (não solicitado).

## Build

Este é um projeto Gradle multi-módulo padrão para Android/Wear OS (`settings.gradle.kts` +
`build.gradle.kts` na raiz/app). Não pode ser compilado neste ambiente somente-texto; abra com
o Android Studio (Hedgehog ou superior) com um emulador/dispositivo alvo Wear OS 3+.
