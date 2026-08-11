# Vai Márcia — watchOS

App companion em SwiftUI, pareado com um app companion iOS via `WatchConnectivity`. Veja
`docs/ARCHITECTURE.md` e `docs/DEVICE_DETECTION.md` na raiz do repositório para o design
multiplataforma que este app implementa.

## Sobre o `VaiMarciaWatch.xcodeproj`

Um `.xcodeproj` escrito manualmente (um formato pbxproj extremamente frágil e majoritariamente
binário) não pode ser produzido de forma confiável fora do próprio Xcode. Em vez disso, este
diretório inclui uma especificação do [XcodeGen](https://github.com/yonaskolb/XcodeGen),
`project.yml`, descrevendo o target `VaiMarciaWatchApp`, suas entradas de Info.plist e
configurações de build. Para gerar o projeto real:

```sh
brew install xcodegen   # se ainda não estiver instalado
cd apps/watchos
xcodegen generate       # gera o VaiMarciaWatch.xcodeproj
open VaiMarciaWatch.xcodeproj
```

Essa é a abordagem pragmática padrão para versionar a *fonte da verdade* de um projeto Xcode
sem incluir um artefato binário que se desalinha da origem do plist ou gera conflitos de merge
ruins no git.

## Estrutura

- `Domain/` — structs/enums Swift puros (`AudioClip`, `Category`, `PlaybackStrategy`,
  `DeviceCapabilityProfile`). Sem imports de SDKs de plataforma (apenas Foundation).
- `Data/Local/` — `AudioCacheManager` (arquivos `.m4a` em cache sob `Documents/AudioCache`) e
  `CatalogStore` (persistência de catálogo baseada em arquivo JSON — veja a observação abaixo
  sobre o porquê de não usar SwiftData).
- `Data/Companion/` — `WatchConnectivityManager` envolve o `WCSession`: `sendPlayCommand` (com
  fallback via `transferUserInfo` quando o celular não está imediatamente alcançável), ativação
  de sessão, e recebimento de sincronizações de catálogo enviadas pelo celular.
- `Playback/` — `DirectPlaybackEngine` (`AVAudioPlayer`, categoria `.playback`, Cenário A),
  `RelayPlaybackDispatcher` (Cenário B, delega para `WatchConnectivityManager`),
  `PlaybackStrategyResolver` (implementa o algoritmo de decisão de
  `docs/DEVICE_DETECTION.md`, incluindo a tabela estática de identificadores de modelo
  Series 8+/Ultra usada para inferir hardware de áudio Bluetooth direto já que o watchOS não
  possui uma API de capacidade em tempo de execução para isso), e `PlaybackController` como a
  única fachada que a UI chama.
- `Presentation/` — `VaiMarciaWatchApp` (ponto de entrada `@main`), `GameModeView` (grade de
  botões grandes), `FirstRunSetupView`, e `Theme.swift` com cores provisórias da marca TogPlay.

## Por que armazenamento em arquivo JSON em vez de SwiftData

O `project.yml` tem como alvo o watchOS 9.0 (para incluir dispositivos Series 4+, que usam o
modo `RELAY` por padrão conforme a tabela de compatibilidade), mas o SwiftData exige watchOS
10+. O `CatalogStore` usa um arquivo JSON simples em `Documents/` em vez disso, mantendo o piso
de implantação baixo sem abrir mão de persistência local estruturada.

## O que está implementado vs. esqueleto

Implementado (código real e idiomático, mas não compilado neste ambiente):
- Modelo de domínio completo, wrapper de companion via WCSession com fallback de
  alcançabilidade, engine de reprodução direta com AVAudioPlayer, dispatcher de relay,
  resolvedor de estratégia seguindo o algoritmo documentado (incluindo a lista estática de
  identificadores de modelo permitidos), views SwiftUI para o Modo Jogo e configuração de
  primeira execução.

Esqueleto / TODO:
- `GameModeView.onCategoryTapped` escolhe um audioId provisório `"\(category.id)_default"`
  em vez de um caso de uso real de "escolher o próximo clipe da categoria" — mesmo ponto de
  extensão do app Wear OS, deixado pelo mesmo motivo (regras de negócio de catálogo não
  especificadas nos documentos de arquitetura).
- A detecção de capacidade LE Audio / LC3 em `PlaybackStrategyResolver` está fixada em `false`.
- Sem política de expurgo de cache para o `AudioCacheManager` (crescimento ilimitado além do
  pacote inicial).
- Ícone do app / imagens do catálogo de assets não foram fabricados; os assets finais da marca
  TogPlay serão fornecidos pelo design e inseridos no `Assets.xcassets` (ainda não criado).
