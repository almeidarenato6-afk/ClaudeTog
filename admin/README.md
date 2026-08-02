# Vai Márcia — Painel Admin

Painel web (React + TypeScript + Vite) usado pela equipe TogPlay para gerenciar o conteúdo e
operação do app "Vai Márcia": cadastro de áudios, categorias, analytics de uso, notificações
push e as promoções/banners exibidos na "Loja TogPlay".

Ver [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) na raiz do monorepo para o contexto completo do sistema.

## Stack

- React 18 + TypeScript, Vite
- React Router para navegação
- TanStack Query (`@tanstack/react-query`) para data fetching/cache
- React Hook Form + Zod para formulários e validação
- Tailwind CSS para estilo
- Recharts para os gráficos de analytics
- Firebase JS SDK (`firebase/app`, `firebase/auth`, `firebase/firestore`,
  `firebase/functions`, `firebase/storage`)

## Setup

```bash
cd admin
npm install
cp .env.example .env.local   # preencha com a config real do Firebase (ver abaixo)
npm run dev
```

Outros scripts:

- `npm run build` — type-check (`tsc -b`) + build de produção (`vite build`)
- `npm run preview` — serve o build de produção localmente
- `npm run lint` — ESLint

## Configuração do Firebase

Este painel foi construído **antes** do backend (`backend/`) estar finalizado, então ele não
tem a config real do projeto Firebase. Preencha `.env.local` com os valores reais assim que o
time de backend disponibilizar o projeto (Firebase Console → Project settings → General → Your
apps → Web app). Ver `.env.example` para a lista completa de variáveis
(`VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_PROJECT_ID`, etc.).

Para desenvolver contra o Firebase Emulator Suite localmente, defina
`VITE_USE_FIREBASE_EMULATORS=true` — `src/lib/firebase.ts` já conecta os emuladores de Auth,
Firestore, Functions e Storage nas portas padrão quando essa flag está ativa.

## Contrato com o backend

Como o backend está sendo construído em paralelo por outro time, o app não assume nomes de
Cloud Functions/coleções definitivos — ele é escrito contra o contrato **plausível** descrito em
`docs/ARCHITECTURE.md` (§6, §10):

- Coleções Firestore lidas diretamente: `categories`, `audios` (listas/filtros), `notifications`
  (histórico), `promotions`.
- Mutações sempre passam por Cloud Functions `httpsCallable` (nunca escrita direta no
  Firestore pelo client), para manter RBAC e validação centralizados no backend:
  `createAudio`, `updateAudio`, `deleteAudio`, `createCategory`, `updateCategory`,
  `listAnalyticsSummary`, `sendNotification`, `createPromotion`, `updatePromotion`.
- Toda a tipagem desse contrato vive em [`src/lib/api/types.ts`](src/lib/api/types.ts) — é o
  primeiro lugar a ajustar quando `DATABASE_SCHEMA.md`/`API_DESIGN.md` forem publicados pelo
  time de backend com os nomes/formatos reais.
- Os módulos em [`src/lib/api/`](src/lib/api/) (`audios.ts`, `categories.ts`, `analytics.ts`,
  `notifications.ts`, `promotions.ts`, `auth.ts`) são a única camada que fala com o Firebase —
  a UI nunca importa `firebase/*` diretamente.

## Papéis (RBAC)

O login é feito com Firebase Auth (e-mail/senha). O acesso depende de um **custom claim**
`role` no token do usuário, definido pelo backend: `admin` | `content_manager` | `viewer`.

- Sem claim válido → tratado como não autorizado, usuário é mandado para `/login` mesmo que a
  autenticação Firebase Auth em si tenha funcionado (ver `src/lib/api/auth.ts`,
  `subscribeAuthedStaff`).
- `viewer` → acesso somente leitura: todos os botões de criar/editar/excluir/enviar/ativar são
  ocultados via `useRole()` (`src/features/auth/useRole.ts`), não apenas desabilitados — a
  aplicação real da regra continua sendo responsabilidade das Cloud Functions.
- `content_manager` e `admin` → podem gerenciar conteúdo (áudios, categorias, notificações,
  promoções). O código atual não diferencia `admin` de `content_manager` em nenhuma tela; ajuste
  `useRole()`/`isAdmin()` se surgir alguma ação exclusiva de admin (ex.: gerenciar outros
  usuários staff — não implementado neste painel).

## O que está implementado

- Login com Firebase Auth + guarda de rota (`RequireStaff`) baseada no custom claim `role`.
- **Áudios**: listagem com filtro por categoria/status e busca por texto, criar (com upload de
  arquivo para Cloud Storage + progresso), editar, ativar/desativar, excluir com confirmação.
- **Categorias**: listagem, criar/editar (nome, slug, ícone, cor, ordem, ativo/inativo).
- **Analytics**: dashboard com cards de totais (reproduções, usuários, DAU, duração média de
  sessão), gráfico de tendência diária, top áudios, distribuição por estratégia de reprodução
  (`DIRECT`/`RELAY`/`PHONE_ONLY`), por modelo de relógio e por modelo de celular — tudo a partir
  de um único callable `listAnalyticsSummary({ rangeStart, rangeEnd })`.
- **Notificações**: histórico + compositor (título, corpo, público "todos" ou "segmento").
- **Loja & Promoções**: listagem com status calculado (agendada/no ar/expirada/inativa),
  criar/editar (título, descrição, link — pré-preenchido com
  `https://www.lojatogplay.com.br`, datas de início/fim), ativar/desativar.
- Componentes compartilhados (`src/components/`): `Layout`/sidebar, `DataTable`, `Modal`,
  `ConfirmDialog`, `Button`, `FormField`, `Badge`, `EmptyState`, `Spinner`/`ErrorState`.
- Estados de loading/erro/vazio em toda tela que busca dados, e confirmação para a única ação
  destrutiva de fato (excluir áudio).

## O que é stub / pendente de integração real

- **Config do Firebase**: `.env.example` só tem placeholders `TODO`; o app não se conecta a
  nada real até isso ser preenchido.
- **Nomes exatos das Cloud Functions/coleções**: escritos contra o contrato plausível do
  `docs/ARCHITECTURE.md`; reconciliar com `DATABASE_SCHEMA.md`/`API_DESIGN.md` quando existirem.
- **Processamento de áudio**: o client só faz upload do arquivo bruto para
  `audios/uploads/<uuid>.<ext>` no Storage e chama `createAudio({ storagePath, ... })` — toda
  validação/transcodificação/duração é responsabilidade do backend (trigger de Storage ou a
  própria Cloud Function).
- **Segmentação de notificações**: o campo "segmento" no compositor é um texto livre (ex.:
  `usuarios_ativos_7d`); a lista de segmentos válidos ainda não existe em lugar nenhum —
  quando o backend definir segmentos formais, trocar por um `<select>`.
- **Diferenciação `admin` vs `content_manager`**: hoje são tratados como equivalentes para fins
  de UI (ambos podem escrever); nenhuma tela é exclusiva de `admin`.
- **Cores/identidade visual**: paleta placeholder (coral/laranja energético + navy) documentada
  em `tailwind.config.ts`, a ser substituída pelo guia de marca oficial da TogPlay.
- Sem testes automatizados (fora de escopo desta entrega inicial).
