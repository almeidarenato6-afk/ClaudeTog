# API — Cloud Functions

> Este documento reflete as funções **implementadas** e exportadas em `backend/functions/src/index.ts` (fonte de verdade). A maioria das leituras de catálogo acontece via listeners diretos do Firestore SDK nos clients (mais rápido, offline-first nativo); Cloud Functions cobrem escrita administrativa, agregação e ações que exigem validação de servidor.

## Convenções
- Todas as funções são `onCall` (Callable Functions, `firebase-functions/v2/https`), autenticadas via Firebase Auth ID token — sem chaves de API expostas no client.
- Validação de payload com `zod` no servidor (`api/**/*.ts`).
- Erros retornados como `HttpsError` com códigos padronizados (`permission-denied`, `invalid-argument`, `not-found`).
- Autorização checada por `requireAdmin` / `requireContentManager` (helpers em `api/admin/middleware.ts`), que leem a custom claim `role` do token — nunca um campo do Firestore.

## Admin API (painel administrativo) — `src/api/admin/`

| Função | Papel mínimo | Descrição |
|---|---|---|
| `setUserRole` | admin | Define a custom claim `role` de outro usuário (staff) |
| `createAudio` | content_manager | Cria áudio no catálogo (upload já feito no Storage; recebe metadados + `storagePath`/`audioUrl`) |
| `updateAudio` | content_manager | Atualiza metadados/categoria/status |
| `deleteAudio` | content_manager | Soft-delete (`isActive = false`) |
| `createCategory` | content_manager | Cria categoria |
| `updateCategory` | content_manager | Atualiza categoria (nome, slug, ordem, ícone, cor, `isActive`) |
| `listAnalyticsSummary` | viewer (leitura) | Lê `analytics_daily` agregados por período |
| `sendNotification` | admin | Dispara push FCM (tópico/segmento/uid) e grava em `notifications_log` |
| `createPromotion` | admin | Cria promoção/banner da Loja TogPlay |
| `updatePromotion` | admin | Atualiza promoção existente (título, descrição, link, datas, `isActive`, audiência) |

## Public API — `src/api/catalog/`

| Função | Descrição |
|---|---|
| `getStarterPack` | Retorna a lista de áudios `isFeatured`/essenciais para bundle offline do primeiro uso |

## Client API (mobile/watch) — `src/api/client/`

| Função | Descrição |
|---|---|
| `registerDevice` | Grava `DeviceCapabilityProfile` detectado em `users/{uid}/devices/{deviceId}` — só via esta função (Admin SDK), nunca escrita direta do client, para manter os dados de analytics confiáveis |
| `recordAnalyticsEvent` | Ingestão em lote de eventos (`analytics_events`), validados e com `receivedAt` carimbado no servidor |

## Leituras/escritas diretas via Firestore SDK (sem Cloud Function)
- `categories`, `audios` (listener em tempo real, filtro `isActive == true`)
- `promotions` (filtro `isActive == true`, para banner e tela da loja)
- `users/{uid}/favorites/{audioId}`: **leitura e escrita diretas do client**, permitidas pelas regras — favoritar é hot-path de UX e não precisa de validação de servidor além de "é dono do documento?"; ver justificativa completa em `backend/functions/src/api/client/favorites.ts`. Um trigger `onFavoriteWrite` mantém `audios/{id}.favoriteCount` sincronizado.
- `users/{uid}/recordings/{recordingId}`: leitura/escrita direta do dono (upload do arquivo em si vai para Cloud Storage por fora do Firestore).

## Triggers (Cloud Functions orientadas a evento) — `src/triggers/`

| Trigger | Evento | Ação |
|---|---|---|
| `onAudioCreate` | `audios/{id}` create | Valida/normaliza campos, garante defaults (`playCount = 0`, `favoriteCount = 0`) |
| `onUserCreate` | Auth `user.create` (v1 trigger — v2 ainda não tem `onCreate` não-bloqueante) | Cria `users/{uid}` com o `UserProfile` inicial (sem `role`) |
| `onFavoriteWrite` | `users/{uid}/favorites/{audioId}` create/delete | Incrementa/decrementa `audios/{audioId}.favoriteCount` |
| `aggregateDailyAnalytics` | Pub/Sub scheduled (diário) | Lê `analytics_events` do dia, grava rollup em `analytics_daily/{date}`, sincroniza `playCount` denormalizado em `audios` |

## Notificações Push (FCM) — `src/notifications/fcm.ts`
- Alvo: tópico (`{type:'topic', topic}`), segmento (`{type:'segment', segment}`, resolvido server-side para um conjunto de tokens) ou usuário específico (`{type:'uid', uid}`).
- `data` arbitrário no payload permite deep-link no app (ex. abrir categoria, abrir tela da Loja TogPlay).

## Gaps conhecidos / TODO (documentados no código)
- Export de `analytics_events` para BigQuery via Pub/Sub — hoje só Firestore + rollup diário (`aggregateDailyAnalytics`).
- Gerenciamento de Remote Config via Cloud Functions — não implementado.
- Pipeline de IA sobre gravações — apenas o campo `Recording.status = 'processing'` reservado, sem função associada.
- Checkout de e-commerce — apenas campos comentados em `domain/Promotion.ts` como ponto de extensão.
