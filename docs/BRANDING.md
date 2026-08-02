# Identidade visual — Vai Márcia (TogPlay)

> ⚠️ **Placeholder de marca.** Nenhum manual de marca oficial da TogPlay foi fornecido. A paleta e diretrizes abaixo são uma proposta de trabalho, aplicada de forma consistente em `apps/mobile`, `admin/` e nos apps de relógio, para que o produto tenha uma identidade coesa desde já. Substitua por valores oficiais assim que o manual de marca da TogPlay existir — todos os tokens de cor estão centralizados (`apps/mobile/lib/core/theme/`, `admin/src/index.css` / `tailwind.config.ts`) para troca em um único lugar.

## Posicionamento

Premium, esportivo, divertido, direto. Referências de UX citadas no briefing: Apple (clareza, tipografia forte), Spotify (grandes cards de categoria, cor vibrante sobre fundo escuro), Nike Run Club / Strava (energia, big numbers, motivação), Material 3 (sistema, acessibilidade, componentes consistentes).

## Paleta (placeholder)

| Token | Hex | Uso |
|---|---|---|
| `primary` (TogPlay Coral) | `#FF5A36` | Botões de ação, botão "tocar", CTA da loja |
| `secondary` (Areia) | `#F4A340` | Acentos, badges de categoria "Energia"/"Comemoração" |
| `surfaceDark` (Navy profundo) | `#101820` | Fundo do Modo Jogo (alto contraste, economia de bateria em AMOLED) |
| `surfaceLight` | `#FFFFFF` / `#F7F7F5` | Fundo padrão modo claro |
| `success` | `#2ECC71` | Confirmações, pareamento bem-sucedido |
| `error` | `#E74C3C` | Erros, falha de reprodução |
| `onSurfaceMuted` | `#8A93A1` | Texto secundário |

Modo escuro é o padrão do "Modo Jogo" (uso em quadra, sob sol forte — alto contraste e economia de bateria); modo claro é o padrão do app geral e do painel admin.

## Tipografia

- Sistema: `Roboto`/`SF Pro` (fonte do sistema por plataforma, evita custo de carregamento e mantém acessibilidade nativa).
- Pesos: `Bold`/`Black` para rótulos de botão do Modo Jogo (legibilidade a distância, em movimento); `Regular`/`Medium` para texto de apoio.

## Logo e ícone

Não fornecidos neste repositório (nenhum arquivo de logo foi enviado). `store-assets/` documenta as especificações exigidas por cada loja (tamanhos de ícone, splash) para quando a arte final da TogPlay for produzida — ver `docs/PUBLISHING_CHECKLIST.md`.

## Tom de voz

Direto, encorajador, brasileiro, nunca formal. Frases curtas, imperativas, com energia de quadra ("Bora!", "Acredita!"). Mensagens de sistema (erros, onboarding) seguem o mesmo tom: "Vamos configurar seu equipamento" em vez de "Configuração inicial do dispositivo".
