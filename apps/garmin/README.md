# Vai Márcia — Garmin Connect IQ

App companion em Monkey C. Veja `docs/ARCHITECTURE.md` e `docs/DEVICE_DETECTION.md` na raiz do
repositório para o design multiplataforma que este app implementa.

## Por que RELAY por padrão

O SDK Connect IQ da Garmin não oferece a apps de terceiros (Monkey C) uma API para reproduzir
arquivos de áudio locais arbitrários em praticamente nenhum dispositivo atual — o hardware de
áudio do próprio relógio (onde existe, como no alto-falante do fēnix 8) é reservado para
recursos do sistema (chamadas, assistente de voz) e apps proprietários da Garmin, não sendo
exposto aos apps Connect IQ. Por isso, e também porque o SDK não possui uma chamada em tempo de
execução para *perguntar* "este dispositivo consegue reproduzir áudio arbitrário", este app:

1. Nunca tenta a reprodução DIRECT (Cenário A) — não existe um `DirectPlaybackEngine` neste
   app, diferente dos apps Wear OS e watchOS.
2. Sempre opera em RELAY (Cenário B): `Communication/CompanionChannel.mc` envolve
   `Toybox.Communications.transmit()` para enviar um payload leve `{type, audioId}` ao app
   companion no celular pareado via Connect IQ Mobile SDK, e o celular (que já mantém o áudio
   em cache localmente) reproduz o som na caixa Bluetooth pareada.
3. Confirma isso por meio de uma **tabela estática de capacidades**
   (`resources/garmin_capability_table.json`), e não por introspecção em tempo de execução,
   conforme a orientação da Garmin no passo 2 de `docs/DEVICE_DETECTION.md` — o SDK não expõe
   introspecção de saída de áudio na maioria dos dispositivos, então a tabela é a fonte da
   verdade e é consultada no momento de pareamento/verificação de capacidade pelo algoritmo de
   detecção de dispositivo do app mobile (não por este próprio app do relógio, que sempre
   envia apenas comandos RELAY).

## Justificativa do canal persistente

`CompanionChannel` chama `Communications.registerForPhoneAppMessages` uma única vez em
`initialize()` e mantém o canal de transmissão "escutando" durante todo o ciclo de vida do app,
seguindo a orientação de latência de `docs/ARCHITECTURE.md` §4 — re-registrar a cada toque
reintroduziria o custo de negociação da ponte app-celular que o padrão de canal persistente
existe justamente para evitar.

## Estrutura

- `manifest.xml` — manifesto do app Connect IQ: permissão `Communications`, um subconjunto
  realista de dispositivos Connect IQ modernos com tela touch e botões (fēnix 7/8, Venu 2/3,
  Forerunner 955/965, vivoactive 5, epix 2), idiomas pt-BR + en.
- `monkey.jungle` — configuração de build (caminhos de source/resource).
- `resources/strings/strings.xml` — rótulos de botão/status em pt-BR.
- `resources/drawables/` — nenhum asset de ícone binário é fabricado aqui; veja
  `PLACEHOLDER.txt` para o que o design precisa fornecer e como conectá-lo quando disponível.
- `resources/garmin_capability_table.json` — a tabela estática de capacidades por modelo
  descrita acima. Toda entrada atualmente tem `canPlayArbitraryLocalAudio: false` e
  `strategy: "RELAY"`; nenhum dispositivo na lista inicial é compatível com DIRECT via Connect
  IQ atualmente.
- `source/VaiMarciaApp.mc` — ponto de entrada `Application.AppBase`.
- `source/Domain/AudioClip.mc` — `AudioClip` e `Category` — classes/constantes Monkey C
  simples, sem imports de `Toybox.WatchUi`/`Toybox.Communications` (mantido livre de
  dependências, como as camadas de domínio das outras plataformas).
- `source/Communication/CompanionChannel.mc` — o canal de comando RELAY (veja acima).
- `source/Views/GameModeView.mc` — lista "Modo Jogo" baseada em `WatchUi.Menu2` (o modelo de UI
  da Garmin é baseado em botões/menu em muitos dispositivos, não uma grade touch livre, então
  um menu é o equivalente idiomático de uma-ação-por-toque à grade de botões grandes nas outras
  plataformas) além de `PlaybackStatusView`, um breve toast de status já que o RELAY não tem
  feedback de alto-falante local para indicar "está tocando" como o DIRECT tem.
- `source/Delegates/GameModeDelegate.mc` — `Menu2InputDelegate` conectando a seleção de menu a
  `CompanionChannel.sendPlayCommand`.

## Adicionando um novo dispositivo

1. Adicione o product id em `<iq:products>` no `manifest.xml`.
2. Adicione uma entrada em `resources/garmin_capability_table.json` com valores reais —
   assuma `canPlayArbitraryLocalAudio: false` / `strategy: "RELAY"` por padrão, a menos que a
   Garmin tenha lançado uma API Connect IQ de saída de áudio documentada para aquele modelo.
3. Se o formato/resolução de tela do dispositivo precisar de recursos de layout distintos,
   adicione uma linha `<deviceId>.resourcePath` em `monkey.jungle`.

## O que está implementado vs. esqueleto

Implementado: manifesto, configuração de build, strings, tabela de capacidades, modelo de
domínio, canal companion RELAY com tratamento de transmissão/confirmação, UI Menu2 + feedback
de status, delegate de seleção.

Esqueleto / TODO:
- `GameModeDelegate.onSelect` envia um audioId provisório `categoryId + "_default"` em vez de
  resolver um clipe específico dentro da categoria — mesmo ponto de extensão dos apps Wear
  OS/watchOS.
- Sem UI de alternância de favoritos (a categoria Favoritos é listada como qualquer outra;
  alternar um favorito é uma ação do lado do celular, conforme a arquitetura).
- Sem PNGs de ícone do app (veja `resources/drawables/PLACEHOLDER.txt`).
- Sem testes unitários (o test harness do Connect IQ exige o simulador do SDK, indisponível
  aqui).
