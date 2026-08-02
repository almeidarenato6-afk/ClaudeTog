# Arquitetura — Vai Márcia (TogPlay)

## 1. Visão geral

O Vai Márcia é um sistema distribuído com cinco frentes de cliente (Android, iOS, Wear OS, watchOS, Garmin Connect IQ), um backend serverless e um painel administrativo web, todos consumindo um catálogo de conteúdo central e compartilhando um mesmo contrato de dados e analytics.

```
┌─────────────────────────────────────────────────────────────────────┐
│                              TogPlay Cloud                           │
│  ┌───────────┐  ┌────────────────┐  ┌───────────┐  ┌──────────────┐  │
│  │ Firestore │  │ Cloud Functions │  │  Storage  │  │ Remote Config│  │
│  │ (catálogo,│  │  (API/regras de │  │  (áudios, │  │ (feature     │  │
│  │  usuários,│  │  negócio,       │  │  imagens) │  │  flags,      │  │
│  │  eventos) │  │  analytics,     │  │           │  │  A/B tests)  │  │
│  │           │  │  notificações)  │  │           │  │              │  │
│  └───────────┘  └────────────────┘  └───────────┘  └──────────────┘  │
│         ▲                ▲                                 ▲          │
└─────────┼────────────────┼─────────────────────────────────┼──────────┘
          │ REST/Callable  │ Admin SDK                        │ Config
          │                │                                  │
  ┌───────┴────────┐  ┌────┴─────────┐                 ┌──────┴──────┐
  │  App Mobile    │  │ Painel Admin │                 │ Notificações │
  │ (Flutter,      │  │ (React/TS,   │                 │  Push (FCM)  │
  │  Android/iOS)  │  │  web)        │                 └─────────────┘
  └───────┬────────┘
          │ Companion channel (Wearable Data Layer / WatchConnectivity / BLE)
   ┌──────┼──────────┬─────────────────┐
   ▼                 ▼                 ▼
┌─────────┐   ┌─────────────┐   ┌─────────────┐
│ Wear OS │   │  watchOS    │   │   Garmin    │
│ (Kotlin/│   │  (SwiftUI)  │   │ (Connect IQ,│
│ Compose)│   │             │   │  Monkey C)  │
└─────────┘   └─────────────┘   └─────────────┘
```

## 2. Princípios

- **Clean Architecture** em todos os clientes: `domain` (entidades + casos de uso, puro Dart/Kotlin/Swift, sem dependência de framework) → `data` (repositórios, fontes de dados local/remota) → `presentation` (UI + state management).
- **Repository Pattern** para toda fonte de dados (catálogo de áudio, favoritos, usuário, analytics), permitindo trocar Firestore por outra fonte sem tocar domínio.
- **Offline-first**: toda leitura passa primeiro pelo cache local (Drift/SQLite + arquivos de áudio já baixados); a rede só enriquece/atualiza.
- **SOLID** e injeção de dependência (`get_it` + `injectable` no Flutter; Hilt no Wear OS; construtor/protocolo no watchOS).
- **Módulos independentes**: cada app é um projeto nativo separado no monorepo, compartilhando apenas contratos (schemas JSON, nomes de eventos de analytics, IDs de categoria) — nunca código de runtime entre plataformas de linguagens diferentes.
- **Latência como requisito de produto, não detalhe técnico** (ver §4).

## 3. Cenários de operação (obrigatório)

O núcleo do produto é decidir, por dispositivo, qual dos dois modos usar — automaticamente, sem perguntar ao usuário.

### Cenário A — Relógio → Caixa Bluetooth (direto)

Válido quando o smartwatch consegue: (1) manter um socket/stream de áudio Bluetooth Classic ou BLE Audio ativo, e (2) reproduzir arquivos locais armazenados nele.

```
[Smartwatch] --(áudio via Bluetooth Classic A2DP / LE Audio)--> [Caixa JBL/etc.]
```

- Wear OS: usa `MediaPlayer`/`ExoPlayer` local + rotas de áudio Bluetooth do sistema (o Wear OS roteia A2DP nativamente quando o watch tem rádio Bluetooth Classic — ex. Galaxy Watch, Pixel Watch conectados diretamente a uma caixa).
- watchOS: reprodução local via `AVAudioPlayer`; roteamento de saída Bluetooth gerenciado pelo `AVAudioSession` (Apple Watch com Bluetooth Classic ou watchOS ≥ 9 com áudio direto).
- Garmin: reprodução limitada pelo Connect IQ SDK — avaliar dispositivo a dispositivo (poucos Garmin tocam áudio arbitrário; muitos só emitem tons/vibração). Nesses casos o app Garmin opera **sempre** em Cenário B.

### Cenário B — Relógio → Celular → Caixa Bluetooth (retransmissão)

Válido para a maioria dos smartwatches (sem rádio Bluetooth de áudio dedicado, ou sem API para tocar áudio arbitrário).

```
[Smartwatch] --(comando leve via Data Layer / WatchConnectivity / BLE GATT)--> [Celular] --(A2DP)--> [Caixa Bluetooth]
```

- O relógio envia apenas um **ID de áudio** (poucos bytes) via:
  - Wear OS: `Wearable MessageClient` / `DataClient` (Data Layer API).
  - watchOS: `WatchConnectivity` (`WCSession.sendMessage`, com fallback para `transferUserInfo` se o celular não estiver acessível instantaneamente).
  - Garmin: `Communications.transmit()` via Connect IQ Mobile SDK.
- O celular recebe o comando, já possui o áudio **pré-cacheado localmente**, e o reproduz imediatamente para a caixa Bluetooth já pareada — sem round-trip de rede.
- Do ponto de vista do usuário, a experiência é indistinguível do Cenário A: um toque, som imediato.

### Seleção automática de modo

Ver [`DEVICE_DETECTION.md`](DEVICE_DETECTION.md) para o algoritmo completo. Resumo: na primeira execução (e a cada emparelhamento novo), o app roda uma sonda de capacidades e persiste o resultado como `PlaybackStrategy` (`DIRECT` | `RELAY` | `PHONE_ONLY`), reavaliando se o hardware mudar (novo relógio emparelhado, nova caixa).

## 4. Latência — orçamento e táticas

Meta: **< 150 ms** entre o toque no botão e o início do áudio audível, em qualquer cenário.

| Técnica | Onde | Efeito |
|---|---|---|
| Pré-carregamento de todos os áudios da categoria ativa em buffers de memória (`AudioPlayer` pool, não apenas disco) | Mobile, Wear OS, watchOS | Elimina I/O de disco no caminho crítico |
| Conexão Bluetooth A2DP mantida "quente" (nunca desconectar entre reproduções) | Mobile | Evita handshake A2DP (~1-2s) a cada toque |
| Canal de comando persistente entre relógio e celular (sessão `MessageClient`/`WCSession` sempre viva, não reconectada por toque) | Watch ↔ Mobile | Evita handshake BLE a cada comando |
| Cache local first-class (áudio baixado = arquivo local, nunca stream por padrão) | Todos | Sem dependência de rede no caminho crítico |
| Prioridade de fila de áudio (`AudioFocus`/`AVAudioSession` de categoria `playback`, interrupção imediata de áudio anterior) | Mobile | Reprodução não fica atrás de outro app de áudio |
| Payload de comando mínimo (apenas `audioId`, não o áudio) | Watch → Mobile | Comando trafega em < 10 ms via Data Layer local |

## 5. Camadas do app mobile (Flutter) — Clean Architecture

```
apps/mobile/lib/
├── core/                     # utilitários cross-cutting, DI, erro, roteamento, tema
├── features/
│   ├── audio_playback/
│   │   ├── domain/           # entities, repositories (abstract), use_cases
│   │   ├── data/              # models, datasources (local/remote), repository impl
│   │   └── presentation/      # pages, widgets, state (Riverpod)
│   ├── categories/
│   ├── favorites/
│   ├── recording/
│   ├── device_pairing/        # detecção de hardware + estratégia de reprodução
│   ├── bluetooth/              # abstração de transporte Bluetooth
│   ├── watch_companion/        # canal de comunicação com o smartwatch
│   ├── auth/
│   ├── store/                  # Loja TogPlay (webview/deep link) + banner
│   ├── notifications/
│   └── analytics/
└── main.dart
```

Cada `feature` é verticalmente independente e só se comunica com outras via `domain` (nunca `presentation` → `presentation` direto).

## 6. Backend

- **Firestore**: catálogo de áudios/categorias, perfis de usuário, favoritos, eventos de analytics agregados, configuração de loja/banners, promoções.
- **Cloud Storage**: arquivos de áudio (masters + versões comprimidas por plataforma), ícones de categoria.
- **Cloud Functions (TypeScript)**: API HTTPS/Callable para o painel admin, triggers de agregação de analytics, envio de notificações (FCM), validação de upload de áudio.
- **Firebase Auth**: Google, Apple, e-mail/senha, anônimo (com upgrade de conta posterior).
- **Remote Config**: feature flags, rollout gradual, parâmetros de banner da loja.
- **FCM**: notificações (novo áudio, promoção, categoria nova).

Ver [`DATABASE_SCHEMA.md`](DATABASE_SCHEMA.md) e [`API_DESIGN.md`](API_DESIGN.md).

## 7. Atualização de conteúdo sem publicar nova versão do app

Áudios e categorias vivem inteiramente no Firestore/Storage. O app observa a coleção `audios` com listeners em tempo real (ou polling com ETag quando offline-first exige menor uso de bateria) e baixa deltas incrementais. Nenhum áudio é embarcado no binário além de um pacote "starter" mínimo para uso 100% offline no primeiro uso.

## 8. Preparação para IA (não implementar agora)

A camada `data` de `recording` já isola o pipeline de processamento de áudio atrás de uma interface `AudioProcessingPipeline` com um único estágio hoje (`PassthroughStage`). Estágios futuros (`NoiseReductionStage`, `VoiceEnhancementStage`, `PhraseSegmentationStage`, `AutoCategorizationStage`) plugam nessa mesma interface sem alterar o restante do app — ver `apps/mobile/lib/features/recording/domain/pipeline/`.

## 9. Loja TogPlay e futuro e-commerce

A seção "Loja TogPlay" é tratada como um `feature` próprio (`features/store/`) com um `StoreRepository` abstrato hoje implementado apenas por `ExternalLinkStoreRepository` (abre `https://www.lojatogplay.com.br` via deep link/WebView). A interface já modela `Product`, `Promotion`, `Cart` como entidades de domínio para que uma implementação futura (`EcommerceApiStoreRepository`) substitua a atual sem alterar a UI.

## 10. Segurança

- Regras de segurança do Firestore/Storage por usuário (`request.auth.uid`), com áudios gravados privados por padrão.
- Tokens de sessão via Firebase Auth (JWT curto + refresh).
- Painel admin com RBAC (roles `admin`, `content_manager`, `viewer`) validado em Cloud Functions, nunca só no client.
- Nenhuma credencial de terceiro (JBL, etc.) é necessária — a comunicação Bluetooth usa apenas os perfis padrão A2DP/AVRCP do sistema operacional.

## 11. Escalabilidade

- Firestore particionado por coleções (`audios`, `categories`, `users/{uid}/favorites`, `analytics_events`) evita hot-spots.
- Cloud Functions stateless, autoscaling nativo do GCP.
- CDN (Firebase Hosting/Storage + cache-control longo) para arquivos de áudio, já que são imutáveis por versão.
- Analytics de alto volume gravado via Pub/Sub → BigQuery (Firebase Analytics export) em vez de Firestore direto, evitando custo/contenção em escala.
