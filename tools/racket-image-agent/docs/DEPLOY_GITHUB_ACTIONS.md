# Deploy — GitHub Actions (cron)

Alternativa sem infraestrutura de nuvem propria: um workflow agendado que
instala o agente e executa `--real-run` (ou `--dry-run` para validacao).

> Este projeto **nao** inclui um workflow ja ativo em `.github/workflows/`
> para este agente — copie o YAML abaixo para
> `.github/workflows/racket-image-agent.yml` quando estiver pronto para
> ativar o agendamento, para nao disparar execucoes automaticas antes das
> credenciais/config estarem configuradas nos Secrets do repositorio.

## 1. Configurar Secrets do repositorio

Em `Settings > Secrets and variables > Actions`, crie:

| Secret | Conteudo |
|---|---|
| `GOOGLE_CREDENTIALS_JSON` | Conteudo JSON completo da service account (ou authorized-user) |
| `GOOGLE_DRIVE_ROOT_FOLDER_ID` | ID da pasta raiz no Drive |
| `CATALOG_SPREADSHEET_ID` | ID da planilha de catalogo |
| `FOTOS_ECOMMERCE_FOLDER_ID` | (opcional) ID direto da pasta "Fotos E-commerce" |
| `AGENT_REPORTS_FOLDER_ID` | (opcional) ID da pasta de relatorios no Drive |

## 2. Workflow (`.github/workflows/racket-image-agent.yml`)

```yaml
name: racket-image-agent

on:
  schedule:
    # Segunda-feira as 08:00 America/Sao_Paulo = 11:00 UTC (UTC-3, sem
    # horario de verao no Brasil desde 2019). Cron do GitHub Actions e
    # sempre em UTC.
    - cron: "0 11 * * 1"
  workflow_dispatch:
    inputs:
      dry_run:
        description: "Executar em modo dry-run"
        type: boolean
        default: true

jobs:
  run-agent:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: tools/racket-image-agent
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"

      - name: Instalar dependencias
        run: pip install -e .

      - name: Rodar testes
        run: pytest -q

      - name: Executar agente
        env:
          GOOGLE_CREDENTIALS_JSON: ${{ secrets.GOOGLE_CREDENTIALS_JSON }}
          GOOGLE_DRIVE_ROOT_FOLDER_ID: ${{ secrets.GOOGLE_DRIVE_ROOT_FOLDER_ID }}
          CATALOG_SPREADSHEET_ID: ${{ secrets.CATALOG_SPREADSHEET_ID }}
          FOTOS_ECOMMERCE_FOLDER_ID: ${{ secrets.FOTOS_ECOMMERCE_FOLDER_ID }}
          AGENT_REPORTS_FOLDER_ID: ${{ secrets.AGENT_REPORTS_FOLDER_ID }}
          TIMEZONE: America/Sao_Paulo
        run: |
          if [ "${{ github.event.inputs.dry_run }}" = "false" ]; then
            racket-image-agent --real-run
          else
            racket-image-agent --dry-run
          fi

      - name: Publicar relatorios como artefato
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: racket-image-agent-relatorios
          path: tools/racket-image-agent/data/relatorios/
```

Disparo agendado (`schedule`) sempre roda com os defaults do workflow (sem
`inputs`), portanto rode em `--dry-run` por padrao no `schedule` ate a
homologacao ser concluida; troque a logica do passo "Executar agente" para
`--real-run` direto quando estiver pronto para producao, ou mantenha a
alternancia via `workflow_dispatch` para testes manuais.
