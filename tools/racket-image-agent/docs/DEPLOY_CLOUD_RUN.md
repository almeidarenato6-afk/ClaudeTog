# Deploy — Google Cloud Run Jobs + Cloud Scheduler (opcao preferida)

O agente roda um lote e termina (nao e um servidor HTTP), entao o encaixe
natural no Cloud Run e um **Job** (nao um Service). O Cloud Scheduler
aciona o Job semanalmente chamando a API `run.googleapis.com` diretamente,
autenticado via OIDC — sem precisar de nenhum wrapper HTTP no codigo do
agente.

Substitua os placeholders `SEU_PROJETO`, `SUA_REGIAO` (ex.: `southamerica-east1`)
e `SEU_REPOSITORIO_ARTIFACT_REGISTRY` pelos valores reais antes de rodar.

## 1. Pre-requisitos

```bash
gcloud config set project SEU_PROJETO

gcloud services enable \
  run.googleapis.com \
  cloudscheduler.googleapis.com \
  artifactregistry.googleapis.com \
  drive.googleapis.com \
  sheets.googleapis.com \
  secretmanager.googleapis.com
```

## 2. Service account do agente

```bash
gcloud iam service-accounts create racket-image-agent \
  --display-name="Racket Image Agent"

# Permissoes minimas: o agente le/escreve apenas no Drive (via
# compartilhamento direto da pasta/Shared Drive - NAO via papel IAM do
# projeto) e le a planilha do catalogo. Nenhuma role de projeto alem de
# invocar o proprio Job e necessaria para a service account de execucao.
```

No Google Drive:

1. Compartilhe a pasta raiz (ou o Shared Drive) que contem "Fotos
   E-commerce" com o e-mail da service account
   (`racket-image-agent@SEU_PROJETO.iam.gserviceaccount.com`), papel
   **Editor/Content Manager**.
2. Compartilhe a planilha do catalogo com o mesmo e-mail, papel **Leitor**.

Gere a chave da service account e guarde no Secret Manager (nunca em
disco/repo):

```bash
gcloud iam service-accounts keys create /tmp/racket-image-agent-key.json \
  --iam-account=racket-image-agent@SEU_PROJETO.iam.gserviceaccount.com

gcloud secrets create racket-image-agent-credentials \
  --data-file=/tmp/racket-image-agent-key.json

rm /tmp/racket-image-agent-key.json
```

## 3. Build e push da imagem

```bash
gcloud artifacts repositories create racket-image-agent \
  --repository-format=docker \
  --location=SUA_REGIAO

gcloud builds submit \
  --tag SUA_REGIAO-docker.pkg.dev/SEU_PROJETO/racket-image-agent/agent:latest \
  tools/racket-image-agent
```

## 4. Criar o Cloud Run Job

```bash
gcloud run jobs create racket-image-agent \
  --image=SUA_REGIAO-docker.pkg.dev/SEU_PROJETO/racket-image-agent/agent:latest \
  --region=SUA_REGIAO \
  --service-account=racket-image-agent@SEU_PROJETO.iam.gserviceaccount.com \
  --set-secrets=GOOGLE_CREDENTIALS_JSON=racket-image-agent-credentials:latest \
  --set-env-vars="GOOGLE_DRIVE_ROOT_FOLDER_ID=REPLACE_WITH_ROOT_FOLDER_ID,CATALOG_SPREADSHEET_ID=REPLACE_WITH_SPREADSHEET_ID,TIMEZONE=America/Sao_Paulo,DRY_RUN=false,LOG_LEVEL=INFO" \
  --max-retries=0 \
  --task-timeout=3600 \
  --args="--real-run"
```

Para testar manualmente antes de agendar:

```bash
# execucao real sob demanda
gcloud run jobs execute racket-image-agent --region=SUA_REGIAO

# variante dry-run (sobrepondo o argumento padrao do Job)
gcloud run jobs execute racket-image-agent --region=SUA_REGIAO --args="--dry-run"
```

## 5. Service account para o Cloud Scheduler acionar o Job

```bash
gcloud iam service-accounts create racket-image-agent-invoker \
  --display-name="Racket Image Agent - Scheduler Invoker"

gcloud run jobs add-iam-policy-binding racket-image-agent \
  --region=SUA_REGIAO \
  --member="serviceAccount:racket-image-agent-invoker@SEU_PROJETO.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

## 6. Cloud Scheduler — toda segunda-feira as 08:00 (America/Sao_Paulo)

```bash
gcloud scheduler jobs create http racket-image-agent-weekly \
  --location=SUA_REGIAO \
  --schedule="0 8 * * 1" \
  --time-zone="America/Sao_Paulo" \
  --uri="https://SUA_REGIAO-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/SEU_PROJETO/jobs/racket-image-agent:run" \
  --http-method=POST \
  --oauth-service-account-email="racket-image-agent-invoker@SEU_PROJETO.iam.gserviceaccount.com"
```

Para disparar manualmente fora do horario agendado (teste do Scheduler):

```bash
gcloud scheduler jobs run racket-image-agent-weekly --location=SUA_REGIAO
```

## 7. Observabilidade

- Logs estruturados em JSON ficam disponiveis no Cloud Logging
  automaticamente (o agente escreve JSON em stdout).
- Configure um alerta de log-based metric para `level=ERROR` no Cloud
  Monitoring, se desejar notificacao proativa de falhas.
- Os relatorios (JSON/CSV/MD) sao gravados em `REPORTS_DIR` dentro do
  container (efemero); se quiser retencao, defina `AGENT_REPORTS_FOLDER_ID`
  para o agente tambem enviar uma copia ao Drive, ou monte um volume/GCS
  (fora do escopo do v1.0 — anote como melhoria futura se necessario).
