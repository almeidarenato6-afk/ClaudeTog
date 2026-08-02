# Estratégia de testes

## Princípios
- Domínio (use cases, regras de decisão como `PlaybackStrategyResolver`) tem cobertura de unidade próxima de 100% — é puro, barato de testar, e é onde bugs custam mais caro (decisão errada de Cenário A/B quebra a experiência central).
- Testes de integração cobrem o caminho crítico: toque → áudio audível.
- Testes manuais em dispositivo físico são obrigatórios para Bluetooth real (emuladores não reproduzem A2DP com hardware real de forma confiável).

## Por área

### Bluetooth / transporte de áudio
- Unidade: `BluetoothTransport` com fake/mocks para os estados (conectado, pareado sem conectar, fora de alcance).
- Integração: matriz manual de caixas (JBL, Sony, Ultimate Ears, Bose, LG, Anker, Marshall + um genérico) × plataformas, checklist de pareamento e latência medida (ver métrica em `ARCHITECTURE.md` §4).
- Regressão: teste de reconexão automática após a caixa dormir/reconectar.

### Smartwatch (companion channel)
- Unidade: `WearCompanionClient`/`WatchConnectivityManager`/`CompanionChannel` (Garmin) com transporte mockado, garantindo que `sendPlayCommand(audioId)` serializa o payload mínimo esperado.
- Integração: teste ponta a ponta relógio físico → celular físico → caixa, para cada plataforma suportada, medindo latência.
- Teste de fallback: celular fora de alcance/bloqueado → comportamento definido (fila local no relógio ou feedback de erro, nunca crash).

### Áudio (playback)
- Unidade: `PlayAudioUseCase`/`PreloadCategoryUseCase` — preload popula pool antes do primeiro toque; troca de categoria não deve interromper áudio em reprodução.
- Teste de latência automatizado (medir tempo entre `play()` e callback `onPlaybackStarted` do player) com limiar de alerta (> 150 ms falha o teste em CI local/dispositivo).
- Teste de interrupção (chamada telefônica, outro app de mídia) — áudio deve pausar/retomar corretamente via `AudioFocus`/`AVAudioSession`.

### Sincronização de catálogo / offline
- Unidade: repositório local vs remoto — leitura sempre prioriza cache; escrita remota atualiza cache.
- Integração: modo avião ligado → app abre, categorias/áudios do starter pack tocam normalmente; favoritos feitos offline sincronizam ao reconectar.

### Login / Auth
- Unidade: cada provider (Google, Apple, email, anônimo) com SDK mockado.
- Integração: fluxo de upgrade de conta anônima → conta permanente sem perda de favoritos/gravações.

### Analytics
- Unidade: eventos gerados nos pontos corretos (play, favorite, session start/end) com payload correto.
- Verificação de que nenhum evento de PII além do necessário é enviado (compliance com política de privacidade).

### Performance
- Cold start medido em dispositivo de referência médio (não apenas topo de linha) — meta documentada em `ARCHITECTURE.md`/`ROADMAP.md`.
- Perfil de memória durante uso prolongado do Modo Jogo (sem vazamento de `AudioPlayer` ao trocar categorias repetidamente).
- Consumo de bateria em sessão de 30 min com relógio conectado via BLE — comparado entre Cenário A e B.

## Ferramentas
- Flutter: `flutter_test`, `mocktail`, `integration_test` (Android/iOS reais via device farm antes de cada release).
- Backend: `firebase-functions-test` + emuladores locais (Firestore, Functions, Auth) para testes de regras de segurança e Cloud Functions.
- Admin: Vitest + Testing Library para componentes/formulários críticos (criar áudio, enviar notificação).
- Wear OS/watchOS/Garmin: testes de unidade nativos (JUnit/Espresso, XCTest, e testes manuais via simulador Connect IQ para Garmin, já que device farms para Garmin são limitados).

## Gate de release
Nenhuma versão vai para as lojas sem: suíte de unidade verde, teste manual de matriz de caixas Bluetooth (mínimo 3 marcas), teste de latência dentro da meta, teste de fluxo offline completo, revisão de regras de segurança do Firestore/Storage.
