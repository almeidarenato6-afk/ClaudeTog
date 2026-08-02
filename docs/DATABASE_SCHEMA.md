# Modelo de dados — Firestore

> Este documento reflete o schema **implementado** em `backend/functions/src/domain/` e `backend/firestore.rules` (fonte de verdade). Tipos completos, incluindo os DTOs de create/update, estão nos arquivos TypeScript referenciados por seção.

## Coleções

### `categories/{categoryId}` — `domain/Category.ts`
```ts
{
  id: string;
  name: string;        // display, ex. "Motivação"
  slug: string;          // chave estável kebab-case, ex. "motivacao"
  order: number;
  icon: string;            // chave de ícone resolvida no client, não é URL
  color: string;             // hex, ex. "#FF6B00"
  isActive: boolean;          // soft delete
  audioCount: number;           // denormalizado, mantido por triggers
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```
Categorias oficiais de lançamento: Motivação, Energia, Incentivo, Comemoração, Recuperação, Concentração, Humor, Treinador, Parceiro (seed em `backend/seed/`). "Personalizados" corresponde às gravações privadas do usuário (`users/{uid}/recordings`), não uma categoria própria no catálogo público.

### `audios/{audioId}` — `domain/AudioClip.ts`
```ts
{
  id: string;
  categoryId: string;
  title: string;         // rótulo curto no botão, ex. "Vai Márcia!"
  phrase: string;           // frase completa/transcrição
  audioUrl: string;           // URL pública de download (Storage)
  storagePath: string;          // caminho canônico, ex. catalog/audios/{id}/master.m4a
  durationMs: number;
  order: number;
  isActive: boolean;              // soft delete — nunca hard-delete de catálogo
  isFeatured: boolean;              // destaque / starter pack
  tags: string[];
  locale: string;                     // BCP-47, ex. "pt-BR"
  playCount: number;                    // denormalizado, só incrementado server-side
  favoriteCount: number;                  // denormalizado, sincronizado por onFavoriteWrite
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;                        // uid do admin/content_manager
}
```

### `users/{uid}` — `domain/UserProfile.ts`
```ts
{
  uid: string;
  displayName: string | null;
  email: string | null;
  photoURL: string | null;
  authProvider: 'google' | 'apple' | 'email' | 'anonymous';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  lastActiveAt: Timestamp;
}
```
> **Decisão deliberada**: este documento **não** tem campo `role`. Papéis (`admin` | `content_manager` | `viewer`) existem **somente** como Firebase Auth custom claims, setados exclusivamente por Cloud Functions via Admin SDK (`api/admin/auth.ts::setUserRole`). Espelhar o papel no documento do próprio usuário abriria escalonamento de privilégio trivial (o usuário poderia escrever `role: 'admin'` no próprio doc). Ver `domain/UserProfile.ts` para o tipo `Role`.

### `users/{uid}/favorites/{audioId}` — `domain/Favorite.ts`
```ts
{ audioId: string; createdAt: Timestamp; }
```
Escrita direta do client (não é uma Cloud Function) — ver justificativa em `backend/functions/src/api/client/favorites.ts`. Um trigger `onFavoriteWrite` mantém `audios/{audioId}.favoriteCount` sincronizado.

### `users/{uid}/devices/{deviceId}` — `domain/Device.ts`
```ts
{
  deviceId: string;
  platform: 'ios' | 'android' | 'wearos' | 'watchos' | 'garmin';
  watchModel?: string;
  phoneModel?: string;
  bluetoothSpeakerBrand?: string;
  playbackStrategy: 'DIRECT' | 'RELAY' | 'PHONE_ONLY'; // espelha PlaybackStrategy de DEVICE_DETECTION.md
  fcmToken?: string;
  appVersion: string;
  osVersion: string;
  createdAt: Timestamp;
  lastSeenAt: Timestamp;
}
```
Escrita somente via a função `registerDevice` (Admin SDK) — nunca direto do client — para manter os dados de capability probing confiáveis para segmentação de analytics.

### `users/{uid}/recordings/{recordingId}` — `domain/Recording.ts`
```ts
{
  id: string;
  storagePath: string;    // users/{uid}/recordings/{fileName}
  durationMs: number;
  status: 'uploaded' | 'processing' | 'ready' | 'failed'; // 'processing' reservado para pipeline de IA futuro
  createdAt: Timestamp;
}
```
Privado por padrão — leitura/escrita restrita ao dono.

### `analytics_events/{eventId}` — `domain/AnalyticsEvent.ts`
```ts
{
  id: string;
  uid: string | null;
  type: 'app_open' | 'session_start' | 'session_end' | 'audio_play' | 'favorite_add' | 'favorite_remove';
  audioId?: string;
  categoryId?: string;
  sessionId?: string;
  sessionDurationMs?: number;   // presente em session_end
  playbackStrategy?: 'DIRECT' | 'RELAY' | 'PHONE_ONLY'; // presente em audio_play
  watchModel?: string;
  phoneModel?: string;
  bluetoothSpeakerBrand?: string;
  platform?: 'ios' | 'android' | 'wearos' | 'watchos' | 'garmin';
  appVersion?: string;
  clientTimestamp: Timestamp;    // quando ocorreu no dispositivo
  receivedAt: Timestamp;           // ingestão no servidor
}
```
Write-only via a função `recordAnalyticsEvent` (nunca escrita/leitura direta do client). Em escala, o caminho recomendado (ainda não implementado) é passar a ingerir via Pub/Sub → BigQuery em vez de Firestore (ver `ARCHITECTURE.md` §11).

### `analytics_daily/{yyyy-mm-dd}`
```ts
{
  date: string;
  totalPlays: number;
  totalSessions: number;
  totalFavoritesAdded: number;
  totalFavoritesRemoved: number;
  activeUsers: number;
  avgSessionDurationMs: number;
  playsByAudio: Record<string, number>;
  playsByCategory: Record<string, number>;
  playsByStrategy: Record<'DIRECT' | 'RELAY' | 'PHONE_ONLY', number>;
  generatedAt: Timestamp;
}
```
Gerado pela função agendada `aggregateDailyAnalytics`, leitura restrita ao painel admin.

### `notifications_log/{notificationId}` — `domain/Notification.ts`
```ts
{
  id: string;
  title: string;
  body: string;
  imageUrl?: string;
  target: { type: 'topic'; topic: string } | { type: 'segment'; segment: string } | { type: 'uid'; uid: string };
  data?: Record<string, string>;
  sentBy: string;   // uid do admin
  sentAt: Timestamp;
  successCount: number;
  failureCount: number;
}
```
Histórico de envios (não é o payload FCM em si — FCM não persiste isso). Escrito apenas pela função `sendNotification`.

### `promotions/{promotionId}` — `domain/Promotion.ts`
```ts
{
  id: string;
  title: string;
  description: string;
  imageUrl?: string;
  linkUrl: string;               // hoje sempre externo, ex. https://www.lojatogplay.com.br
  startAt: Timestamp;
  endAt: Timestamp;
  isActive: boolean;
  audience: 'all' | 'favorites_users';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
  // Ponto de extensão futuro (NÃO implementado): couponCode, discountPercent,
  // cashbackPercent, minPurchaseValue, loyaltyPointsMultiplier
}
```
Leitura pública (alimenta o banner/tela "Loja TogPlay"), escrita restrita a `admin`.

## Índices compostos (`backend/firestore.indexes.json`)
- `audios`: `categoryId ASC, isActive ASC, order ASC`
- `audios`: `isActive ASC, isFeatured ASC, order ASC`
- `audios`: `isActive ASC, playCount DESC`
- `categories`: `isActive ASC, order ASC`
- `promotions`: `isActive ASC, startAt DESC`
- `analytics_events`: `type ASC, clientTimestamp ASC`
- `analytics_events`: `uid ASC, clientTimestamp DESC`

## Regras de acesso (resumo — implementação completa em `backend/firestore.rules` / `backend/storage.rules`)
- `categories`, `audios`: leitura pública; escrita restrita a custom claim `role in ['admin','content_manager']`.
- `users/{uid}` e subcoleções: leitura/escrita restritas ao próprio `uid` — **exceto** `devices/**` (somente leitura do dono; escrita bloqueada no client, só via Admin SDK).
- `analytics_events`, `analytics_daily`: sem leitura/escrita do client; leitura de `analytics_daily` liberada para papéis staff via função `listAnalyticsSummary` (não Firestore direto).
- `notifications_log`, `promotions`: leitura pública onde faz sentido para o app (`promotions`); escrita restrita a `role == 'admin'`.
- Storage: áudio de catálogo público-leitura/admin-escrita com validação de tipo/tamanho; gravações de usuário privadas (dono apenas).
