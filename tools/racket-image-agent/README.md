# racket-image-agent (v1.0)

Agente que coleta, valida e organiza fotos oficiais de raquetes de beach
tennis no Google Drive, a partir de um catalogo em Google Sheets, seguindo
fontes de imagem priorizadas e regras estritas de qualidade/nomenclatura.
Roda em modo **incremental e idempotente**: reexecutar nunca duplica pastas
ou arquivos, e so processa produtos novos ou pastas incompletas.

> Parte do monorepo TogPlay (`/tools/racket-image-agent`), ferramenta
> auxiliar de e-commerce independente do app "Vai Márcia".

## Como funciona (resumo)

1. Le o catalogo de raquetes de uma planilha do Google Sheets.
2. Para cada raquete, calcula o **nome oficial** normalizado (marca +
   modelo [+ versao/cor/ano]).
3. Localiza (por ID do Drive, nao por caminho de texto) a pasta
   correspondente dentro de "Fotos E-commerce"; se a pasta ja tem 5 imagens
   validas, o produto e classificado `IGNORADO` e nada mais e feito.
4. Caso contrario, busca imagens nas fontes, **nesta ordem**:
   1. `prospin.com.br`
   2. Merak Beach Tennis
   3. Site oficial do fabricante
   (paradas assim que houver cobertura suficiente de angulos, para nao
   sobrecarregar as fontes seguintes).
5. Valida cada imagem candidata: tipo real de arquivo, resolucao minima,
   suspeita de marca d'agua, deduplicacao (SHA-256 + perceptual hash) e
   score de confianca de correspondencia com o produto.
6. Seleciona exatamente as 5 fotos na ordem exigida (capa, angulo/verso,
   detalhe, complementar, bag apenas se confirmada) e envia somente as que
   estao faltando (nunca sobrescreve o que ja existe).
7. Gera um relatorio completo (JSON, CSV e Markdown) com tudo que foi
   feito, pendencias e erros.

Tudo isso tambem roda em **modo dry-run** (padrao), que faz toda a
pesquisa/validacao e gera o relatorio, mas nunca cria pastas nem envia
arquivos.

## Estrutura do projeto

```
tools/racket-image-agent/
├── src/racket_image_agent/
│   ├── config.py            # configuracao via variaveis de ambiente
│   ├── models.py             # Product, ImageCandidate, ExecutionReport...
│   ├── name_normalizer.py    # nome oficial + nomenclatura das 5 fotos
│   ├── state_store.py        # cache local de idempotencia
│   ├── matching.py           # score de confianca produto x imagem
│   ├── pipeline.py           # orquestrador principal
│   ├── reporting.py          # relatorio JSON/CSV/MD (+ upload opcional ao Drive)
│   ├── cli.py                 # ponto de entrada `racket-image-agent`
│   ├── imaging/               # validacao, hashing/dedup, selecao das 5 fotos
│   ├── sourcing/               # HTTP c/ rate-limit+retry+circuit breaker,
│   │                            robots.txt, extracao JSON-LD/OG/img,
│   │                            fontes (prospin, Merak, fabricante)
│   └── google/                 # auth, DriveClient, SheetsClient
├── config/
│   ├── sources.json                  # templates de busca por fonte
│   └── manufacturer_domains.json     # dominio oficial por marca (placeholders)
├── tests/                       # os 14 casos obrigatorios + fakes
├── docs/                        # deploy (Cloud Run, GitHub Actions, cron) + homologacao
├── examples/sample_report.*      # exemplo real de relatorio gerado em dry-run
├── scripts/generate_example_report.py
├── Dockerfile
├── .env.example
└── pyproject.toml
```

## Instalacao

```bash
cd tools/racket-image-agent
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## Configuracao de credenciais

1. Copie `.env.example` para `.env` e preencha os valores (nunca faca
   commit do `.env` preenchido).
2. Crie uma service account no Google Cloud com acesso a Drive API e
   Sheets API habilitadas no projeto.
3. **Compartilhe** (no Drive, manualmente) a pasta raiz — ou o Shared
   Drive — que contem "Fotos E-commerce" com o e-mail da service account,
   papel **Editor/Content Manager**. Compartilhe tambem a planilha do
   catalogo, papel **Leitor**.
4. Gere uma chave JSON da service account e aponte
   `GOOGLE_APPLICATION_CREDENTIALS` para o arquivo (uso local) **ou**
   coloque o conteudo JSON inteiro em `GOOGLE_CREDENTIALS_JSON` (uso via
   secret manager em produção).

### Permissoes minimas

| Escopo | Uso | Motivo de ser "completo" e nao `drive.file` |
|---|---|---|
| `https://www.googleapis.com/auth/drive` | Ler/criar pastas e arquivos em "Fotos E-commerce" | O agente precisa enxergar pastas **pre-existentes** que ele nao criou; `drive.file` so enxerga arquivos criados pelo proprio app. Restrinja o raio de acao compartilhando apenas a pasta/Shared Drive necessaria com a service account, em vez de conceder acesso a todo o Drive de um usuario. |
| `https://www.googleapis.com/auth/spreadsheets.readonly` | Ler o catalogo | O agente nunca escreve na planilha. |

Nunca grave credenciais no repositorio; use variaveis de ambiente ou um
secret manager (Secret Manager no Cloud Run, Secrets no GitHub Actions,
arquivo `600` fora do git no cron Linux).

## Fontes de imagem e marcas suportadas

Ordem de busca: `prospin.com.br` → Merak Beach Tennis → site oficial do
fabricante → demais distribuidores/catalogos oficiais (Mercado Livre,
Shopee, OLX, blogs e revendedores nao autorizados nunca sao usados).

Os templates de busca de cada site e os dominios oficiais de fabricante
**nao vem hardcoded com URLs adivinhadas** — ficam como placeholders
explicitos em `config/sources.json` e `config/manufacturer_domains.json`,
para serem confirmados durante a homologacao (ver
`docs/HOMOLOGACAO_CHECKLIST.md`) em vez de inventados.

Marcas cobertas pela normalizacao de nome (`name_normalizer.py`): NOX,
Heroe's, Drop Shot, AMA, Adidas, Bullpadel, Head, Wilson, Babolat, Shark,
Mormaii, Quicksand, Black Crown, LOK, Vision, Joma, Kona, TotalFun, Sexy
Brand — e qualquer outra marca encontrada nas fontes oficiais (usa
title-case como fallback).

## Testes

```bash
pytest -q
```

Cobre os 14 casos obrigatorios: normalizacao de nomes, deteccao de modelos
novos, idempotencia, criacao de pasta ausente, pasta completa ignorada,
pasta incompleta complementada, rejeicao de marca d'agua, rejeicao de
baixa resolucao, duplicidade exata e perceptual, ordem das cinco fotos,
ausencia de bag, falha temporaria de site, falha de API do Google e modo
dry-run.

## Executar

```bash
# modo seco (padrao) - nao cria pastas nem envia arquivos
racket-image-agent --dry-run

# execucao real
racket-image-agent --real-run
```

O relatorio (JSON, CSV, Markdown) e sempre gravado em `REPORTS_DIR`
(padrao `data/relatorios/`); veja um exemplo em `examples/sample_report.*`
e o script que o gerou em `scripts/generate_example_report.py`.

## Deploy e agendamento

Tres opcoes documentadas em `docs/`:

1. **`docs/DEPLOY_CLOUD_RUN.md`** (preferida) — Cloud Run Jobs + Cloud
   Scheduler, segunda-feira 08:00 `America/Sao_Paulo`.
2. **`docs/DEPLOY_GITHUB_ACTIONS.md`** — workflow agendado (cron do GitHub
   Actions, sempre em UTC — o YAML ja calcula o horario equivalente).
3. **`docs/DEPLOY_CRON_LINUX.md`** — `crontab` com `0 8 * * 1` e timezone
   do sistema configurado para `America/Sao_Paulo`.

Antes de ativar qualquer agendamento com `DRY_RUN=false`, complete o
`docs/HOMOLOGACAO_CHECKLIST.md`.

## Observabilidade

- Logs estruturados em JSON (`logging_setup.py`); nunca loga
  tokens/credenciais.
- Retry com backoff exponencial e circuit breaker simples por dominio
  (`sourcing/http_client.py`).
- Timeout por requisicao e rate limiting por dominio.
- Erros por produto nunca interrompem o lote (try/except por item em
  `pipeline.py`); ficam registrados em `errors` no relatorio.

## Comandos de referencia

```bash
# 1) instalar
cd tools/racket-image-agent && python3 -m venv .venv && source .venv/bin/activate && pip install -e ".[dev]"

# 2) configurar credenciais
cp .env.example .env   # edite com os IDs/credenciais reais

# 3) testar
pytest -q

# 4) dry-run
racket-image-agent --dry-run

# 5) execucao real
racket-image-agent --real-run

# 6) build + deploy no Cloud Run (ver docs/DEPLOY_CLOUD_RUN.md para o passo a passo completo)
gcloud builds submit --tag SUA_REGIAO-docker.pkg.dev/SEU_PROJETO/racket-image-agent/agent:latest tools/racket-image-agent
gcloud run jobs create racket-image-agent --image=SUA_REGIAO-docker.pkg.dev/SEU_PROJETO/racket-image-agent/agent:latest --region=SUA_REGIAO ...

# 7) agendar no Cloud Scheduler - segunda-feira 08:00 America/Sao_Paulo
gcloud scheduler jobs create http racket-image-agent-weekly \
  --location=SUA_REGIAO --schedule="0 8 * * 1" --time-zone="America/Sao_Paulo" \
  --uri="https://SUA_REGIAO-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/SEU_PROJETO/jobs/racket-image-agent:run" \
  --http-method=POST --oauth-service-account-email="racket-image-agent-invoker@SEU_PROJETO.iam.gserviceaccount.com"
```
