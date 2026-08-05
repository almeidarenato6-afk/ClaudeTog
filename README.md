# Vai Márcia — by TogPlay

**Vai Márcia** é o aplicativo oficial da **TogPlay** para jogadores de Beach Tennis: dispara áudios motivacionais instantaneamente, pelo celular ou direto do smartwatch, para qualquer caixa de som Bluetooth.

> "Vai Márcia!" · "Bora!" · "Acredita!" · "Agora é nossa!"

## Por que este repositório existe

Este é um monorepo de produto comercial, organizado para escalar para milhares de usuários em Android, iOS, Wear OS, watchOS e Garmin Connect IQ, com backend, painel administrativo e loja integrada da TogPlay.

Leia primeiro: **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)** e **[`docs/ROADMAP.md`](docs/ROADMAP.md)**.

## Estrutura do monorepo

```
claudetog/
├── apps/
│   ├── mobile/        # Flutter — Android + iOS (fonte de verdade do produto)
│   ├── wearos/        # Kotlin + Jetpack Compose — Wear OS (Samsung, Google, etc.)
│   ├── watchos/        # SwiftUI — Apple Watch
│   └── garmin/         # Monkey C — Garmin Connect IQ
├── backend/            # Firebase (Firestore, Cloud Functions, Storage, Auth, Remote Config)
├── admin/              # Painel administrativo web (React + TypeScript)
├── docs/                # Arquitetura, roadmap, backlog, banco de dados, APIs, publicação
├── store-assets/        # Metadados, ícones, política de privacidade, termos de uso
├── tools/
│   └── racket-image-agent/  # Agente de coleta/organização de fotos de raquetes (Google Drive/Sheets)
└── .github/workflows/   # CI/CD
```

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Arquitetura completa, Clean Architecture, cenários A/B de Bluetooth |
| [`docs/DEVICE_DETECTION.md`](docs/DEVICE_DETECTION.md) | Motor de detecção automática de hardware/capacidades |
| [`docs/DATABASE_SCHEMA.md`](docs/DATABASE_SCHEMA.md) | Modelo de dados Firestore |
| [`docs/API_DESIGN.md`](docs/API_DESIGN.md) | Cloud Functions / APIs |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Fases, cronograma, backlog priorizado, estimativas |
| [`docs/PUBLISHING_CHECKLIST.md`](docs/PUBLISHING_CHECKLIST.md) | Checklist de publicação nas lojas |
| [`docs/BRANDING.md`](docs/BRANDING.md) | Identidade visual e diretrizes de marca |
| [`docs/TESTING_STRATEGY.md`](docs/TESTING_STRATEGY.md) | Estratégia de testes |

## Status atual — Fase 0 concluída (fundação)

| Frente | Status |
|---|---|
| Documentação (arquitetura, DB, API, roadmap, publicação, branding, testes) | ✅ Completa |
| `apps/mobile/` (Flutter, Android+iOS) | ✅ Clean Architecture completa em Dart (audio, categorias, favoritos, gravação, auth, loja, notificações, analytics, detecção de dispositivo) — ⚠️ transporte Bluetooth/companion nativo (Kotlin/Swift) scaffolded com TODOs, requer implementação nativa real |
| `backend/` (Firebase) | ✅ Firestore rules/schema, Cloud Functions (admin/client API, triggers), seed data — `tsc --noEmit` limpo. ⚠️ requer projeto Firebase real (`firebase use --add`) |
| `admin/` (React + TS) | ✅ CRUD de áudio/categoria, analytics, notificações, promoções — build e lint limpos. ⚠️ requer `.env` com config do Firebase real |
| `apps/wearos/` (Kotlin/Compose) | ✅ Domínio, cache local, Data Layer client, motor de reprodução direct/relay, Modo Jogo |
| `apps/watchos/` (SwiftUI) | ✅ Domínio, WatchConnectivity, motor de reprodução direct/relay, Modo Jogo (projeto via XcodeGen) |
| `apps/garmin/` (Connect IQ) | ✅ Scaffold RELAY-only (Garmin não expõe áudio de terceiros), tabela de capacidades por modelo |
| CI/CD | ✅ Workflows por app em `.github/workflows/` |
| Ícones, screenshots, certificados | ❌ Pendente — depende de arte final da TogPlay e contas de desenvolvedor reais |
| IA de processamento de áudio / e-commerce completo | ❌ Não implementado por design — apenas os seams de arquitetura preparados (ver `ARCHITECTURE.md` §8–9) |

Veja `docs/ROADMAP.md` para as próximas fases (hardening técnico, beta fechado, lançamento público) e os READMEs de cada `apps/*`/`backend/`/`admin/` para instruções de setup específicas.
