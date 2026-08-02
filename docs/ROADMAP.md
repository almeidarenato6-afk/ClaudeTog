# Roadmap — Vai Márcia (TogPlay)

## Fase 0 — Fundação (este commit)

Arquitetura completa, estrutura de monorepo, banco de dados, contratos de API, wireframe conceitual (descrito em texto no §"Modo Jogo" de `ARCHITECTURE.md` e implementado como `GameModeScreen`/`GameModeView`/`GameModeView.mc`), e implementação inicial em código real (não apenas pastas vazias) de:

- **`apps/mobile/`** (Flutter, Android + iOS): Clean Architecture completa — features de reprodução de áudio, categorias, favoritos, gravação (com seam para IA futura), detecção de dispositivo/estratégia de reprodução, abstração Bluetooth, canal de comunicação com o relógio, autenticação, Loja TogPlay + banner, notificações, analytics. Partes que dependem de APIs nativas de plataforma (Bluetooth Classic profundo, Data Layer/WatchConnectivity) estão como interfaces + platform channel scaffolding com TODOs explícitos — exigem implementação nativa Kotlin/Swift dentro do projeto Flutter na Fase 1.
- **`backend/`**: Firestore schema, regras de segurança, Cloud Functions (admin API, client API, triggers, agregação de analytics), dados de seed.
- **`admin/`**: painel React/TypeScript funcional para CRUD de áudio/categoria, analytics, notificações, promoções.
- **`apps/wearos/`**, **`apps/watchos/`**, **`apps/garmin/`**: scaffolds nativos com domínio, camada de dados, motor de reprodução (direct/relay) e tela de Modo Jogo.
- Documentação completa (este diretório `docs/`).

**Não implementado ainda (por design, conforme escopo do briefing):** processamento de áudio por IA (apenas seam preparado), e-commerce completo (apenas entidades de domínio preparadas), integração final com contas de desenvolvedor reais das lojas (requer credenciais da TogPlay).

## Fase 1 — Hardening técnico (4–6 semanas, 2 devs mobile + 1 backend)

| Item | Esforço |
|---|---|
| Implementar platform channels nativos de Bluetooth (Android `BluetoothA2dp`/iOS `AVAudioSession` roteamento real) | 2 semanas |
| Implementar Wearable Data Layer real (Android) e WatchConnectivity real (iOS) ponta a ponta | 2 semanas |
| `flutterfire configure` com projeto Firebase real da TogPlay + ambientes (dev/staging/prod) | 2 dias |
| Testes de integração em dispositivo físico (matriz de caixas Bluetooth) | 1 semana |
| CI real rodando (lint, testes, build) nos 3 repositórios de app | 3 dias |
| Auditoria de regras de segurança Firestore/Storage com Firebase Emulator | 2 dias |

## Fase 2 — Beta fechado (3–4 semanas)

- Distribuição via TestFlight (iOS) + Play Console faixa interna/fechada (Android) para ~50-100 jogadores de Beach Tennis reais.
- Instrumentação de analytics validada com dados reais (modelo de relógio, estratégia de reprodução, latência percebida via NPS in-app).
- Iteração de UX do Modo Jogo com feedback de uso em quadra (sol forte, mãos suadas, movimento).
- Gravação de áudio próprio validada em campo (qualidade, tamanho de arquivo, limite de gravações por usuário).

## Fase 3 — Lançamento público (2–3 semanas)

- Checklist completo de `docs/PUBLISHING_CHECKLIST.md` fechado para Google Play e App Store (prioridade — maior alcance).
- Wear OS e watchOS publicados em conjunto com os apps de celular.
- Garmin Connect IQ publicado (processo de certificação mais longo — iniciar submissão em paralelo à Fase 2 pela morosidade histórica da revisão Garmin).
- Marketing: banner/loja TogPlay ativo, notificação de lançamento para lista de espera (se houver).

## Fase 4 — Pós-lançamento e crescimento (contínuo)

- Expansão de biblioteca de áudio (mais frases, vozes de treinadores parceiros da TogPlay).
- Início da IA de processamento de áudio (redução de ruído, melhoria de voz) sobre o seam já preparado em `recording/domain/pipeline/`.
- Início de e-commerce embutido (catálogo/carrinho/checkout) sobre as entidades já modeladas em `store/domain/`.
- Programa de fidelidade / cashback (ligado ao roadmap de e-commerce).
- Complicações watchOS, tiles Wear OS, widgets de tela inicial para acesso ainda mais rápido.
- Internacionalização (hoje pt-BR único) se houver demanda de mercados fora do Brasil.

## Backlog priorizado (visão de produto, não exaustivo)

**P0 (bloqueia lançamento)**
1. Reprodução de áudio com latência < 150ms nos dois cenários
2. Detecção automática de estratégia de reprodução
3. Categorias + biblioteca inicial de áudios oficiais
4. Favoritos
5. Login (pelo menos anônimo + um provider social)
6. Loja TogPlay (link/deep link) + banner
7. Modo offline com starter pack
8. Painel admin: CRUD de áudio/categoria (para a TogPlay popular o catálogo antes do lançamento)

**P1 (lançamento com qualidade)**
9. Gravação de áudio próprio
10. Notificações push
11. Analytics completo + dashboard admin
12. Publicação Wear OS + watchOS

**P2 (pode seguir após lançamento)**
13. Garmin Connect IQ (dado o ciclo de certificação mais longo, pode lançar em onda 2)
14. Promoções/notificações de marketing avançadas
15. Multi-idioma

**P3 (futuro, arquitetura já preparada, não implementar agora)**
16. IA de processamento de áudio
17. E-commerce completo (catálogo, cupom, cashback, fidelidade, carrinho, checkout)

## Estimativa de esforço (visão de time, ordem de grandeza)

| Frente | Esforço estimado até lançamento público |
|---|---|
| Mobile (Flutter, Android+iOS) | 8–10 semanas-pessoa |
| Wear OS nativo | 3–4 semanas-pessoa |
| watchOS nativo | 3–4 semanas-pessoa |
| Garmin Connect IQ | 2–3 semanas-pessoa (+ tempo de certificação, fora do controle do time) |
| Backend/Firebase | 4–5 semanas-pessoa |
| Painel admin | 2–3 semanas-pessoa |
| QA/testes em dispositivo real | 2–3 semanas-pessoa, transversal |
| Publicação/compliance | 1–2 semanas-pessoa, transversal |

Total aproximado: **um time enxuto de 3–4 pessoas, 3–4 meses até lançamento público em Android/iOS/Wear OS/watchOS**, com Garmin podendo seguir em onda separada por causa da certificação.

## Cronograma sugerido (a partir de hoje)

```
Semana 1–2   Fase 0 (concluída neste commit) + kickoff de time
Semana 3–8   Fase 1 — hardening técnico
Semana 9–12  Fase 2 — beta fechado
Semana 13–15 Fase 3 — lançamento público (Android/iOS/Wear OS/watchOS)
Semana 13+   Submissão Garmin em paralelo (certificação mais longa)
Semana 16+   Fase 4 — crescimento contínuo
```
