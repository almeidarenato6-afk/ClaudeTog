# Vai Márcia — Backend (Firebase)

Backend em Firestore + Cloud Storage + Cloud Functions (TypeScript) + Firebase Auth para o
app de soundboard Vai Márcia (TogPlay). Veja [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)
para o contexto completo do sistema.

## Estrutura

```
backend/
├── firebase.json / .firebaserc      # project config (fill in the real project ID)
├── firestore.rules / storage.rules  # security rules — see "Security model" below
├── firestore.indexes.json           # composite indexes for catalog queries
├── functions/                       # Cloud Functions (TypeScript, firebase-functions v2)
│   └── src/
│       ├── config/                  # Admin SDK init, env/region config
│       ├── domain/                  # Firestore schema as TS types (source of truth)
│       ├── repositories/            # one class per collection, all Firestore access goes through these
│       ├── api/admin/               # admin-panel callables (custom-claim-gated)
│       ├── api/catalog/             # public catalog callables
│       ├── api/client/              # mobile/watch callables
│       ├── triggers/                # Firestore/Auth/Scheduler triggers
│       └── notifications/           # FCM sending helper
└── seed/                            # one-off script to populate starter catalog data
```

## Configuração

```bash
npm install -g firebase-tools
firebase login

cd backend
firebase use --add          # pick/alias your Firebase project, replacing the TODO in .firebaserc

cd functions
npm install
npm run build
```

## Desenvolvimento local

```bash
cd backend
firebase emulators:start --only functions,firestore,storage,auth
```

A UI do emulador roda em `http://localhost:4000`.

## Deploy

```bash
cd backend
firebase deploy --only firestore:rules,firestore:indexes,storage:rules,functions
```

O Hosting (para o build do painel admin) tem deploy separado assim que `admin/` tiver um
passo de build gerando `admin/dist`:

```bash
firebase deploy --only hosting
```

## Papéis de admin (custom claims)

Os papéis (`admin`, `content_manager`, `viewer`) existem **apenas** como custom claims do
Firebase Auth — nunca espelhados em um documento Firestore que um cliente pudesse escrever.
Não há forma pelo console do Firestore de ver "quem é admin"; verifique as custom claims pelo
console do Firebase (Authentication → usuário → "Custom claims" não aparece ali — use o
Admin SDK/CLI) ou:

```js
// script avulso, execute com GOOGLE_APPLICATION_CREDENTIALS apontando para uma chave de service account
const admin = require("firebase-admin");
admin.initializeApp();
await admin.auth().setCustomUserClaims("<uid-of-first-admin>", { role: "admin" });
```

A partir do primeiro admin existente, toda concessão subsequente de admin/content_manager/viewer
pode passar pelo callable `setUserRole` (restrito a admin) — veja
`functions/src/api/admin/auth.ts`.

Os clientes precisam forçar o refresh do ID token após uma mudança de papel
(`getIdToken(true)` / `getIdTokenResult(true)`) para receber as novas claims.

## Populando conteúdo inicial (seed)

```bash
cd backend/seed
npm install
GOOGLE_APPLICATION_CREDENTIALS=./service-account.json \
STORAGE_BUCKET=<your-project-id>.appspot.com \
npx ts-node seed.ts
```

Grava 9 categorias e 15 documentos `AudioClip` de exemplo (frases motivacionais em português —
"Vai Márcia!", "Bora!", "Acredita!", etc.). Isso cria apenas os documentos no Firestore; **não**
faz upload dos arquivos de áudio `.m4a` de verdade. Faça upload dos masters reais para
`catalog/audios/{audioId}/master.m4a` no Cloud Storage (pelo painel admin quando estiver
pronto, ou via `gsutil cp`) antes que as `audioUrl`s populadas via seed consigam resolver.

## Modelo de segurança

- **Catálogo** (`categories`, `audios`): leitura pública, escrita exige a custom claim `admin`
  ou `content_manager`.
- **Usuários** (`users/{uid}` e tudo abaixo): apenas o dono. `favorites` é escrito diretamente
  pelo cliente (veja `functions/src/api/client/favorites.ts` para entender o motivo);
  `devices` só é escrito via o callable `registerDevice`; `recordings` é privado, leitura/escrita
  apenas do dono.
- **Analytics** (`analytics_events`, `analytics_daily`): nenhum acesso direto do cliente —
  a ingestão é feita via o callable `recordAnalyticsEvent`, os rollups são somente leitura
  para papéis de admin.
- **Promotions**: leitura pública, escrita restrita a `admin`.
- A aplicação das regras acontece em `firestore.rules`/`storage.rules` (a autoridade de fato)
  *e* é reverificada em cada callable de admin via `requireRole`/`requireContentManager`/
  `requireAdmin` — nunca confie apenas em uma checagem do lado do cliente.

## O que já está implementado

- Regras de segurança do Firestore/Storage (dados do usuário apenas para o dono, catálogo com
  leitura pública/escrita admin, analytics apenas via function).
- Tipos de domínio para cada coleção (`functions/src/domain/`).
- Camada de repositórios para acesso ao Firestore (`functions/src/repositories/`).
- Callables de admin: `createAudio`, `updateAudio`, `deleteAudio` (soft delete), `createCategory`,
  `updateCategory`, `listAnalyticsSummary`, `sendNotification`, `createPromotion`,
  `setUserRole`.
- Callable público: `getStarterPack` (categorias + áudios em destaque para o primeiro uso
  offline).
- Callables de cliente: `registerDevice`, `recordAnalyticsEvent` (ingestão em lote).
- Triggers: `onAudioCreate` (rede de segurança de valores padrão), `onUserCreate` (bootstrap
  do perfil), `onFavoriteWrite` (mantém `AudioClip.favoriteCount` sincronizado),
  `aggregateDailyAnalytics` (rollup diário agendado, também sincroniza `AudioClip.playCount`).
- Script de seed com 9 categorias e 15 áudios de exemplo.

## TODOs explícitos / não implementado

- **`deleteCategory`**: as categorias são pensadas para serem de longa duração; desative via
  `updateCategory({ isActive: false })` em vez disso. Adicione um callable dedicado se o painel
  admin precisar de uma ação explícita de "arquivar categoria" além disso.
- **Exportação para o BigQuery de analytics**: hoje `analytics_events` vive só no Firestore.
  Conforme o ARCHITECTURE.md §11, analytics de alto volume deveriam fluir por Pub/Sub até o
  BigQuery — isso está anotado no código (`analyticsEvents.ts`, `aggregateDailyAnalytics.ts`)
  mas ainda não foi construído.
- **Pipeline de processamento de áudio com IA**: `Recording.status` inclui um estado
  `processing` como ponto de extensão (espelha os estágios do `AudioProcessingPipeline` do
  cliente descritos no ARCHITECTURE.md §8), mas hoje nenhum processamento roda no servidor —
  as gravações ficam apenas em `uploaded`/`ready`.
- **E-commerce**: `Promotion` tem um bloco de extensão comentado
  (`couponCode`, `discountPercent`, `cashbackPercent`, `minPurchaseValue`,
  `loyaltyPointsMultiplier`) para uma futura loja dentro do app. Hoje as promoções são apenas
  banners que levam para https://www.lojatogplay.com.br.
- **Remote Config**: feature flags / parâmetros do banner da loja são gerenciados diretamente
  pelo console do Firebase hoje; nenhuma Cloud Function gerencia parâmetros do Remote Config
  programaticamente.
- **`.firebaserc`**: ainda tem um alias de projeto placeholder — substitua pelo ID real do
  projeto via `firebase use --add`.
