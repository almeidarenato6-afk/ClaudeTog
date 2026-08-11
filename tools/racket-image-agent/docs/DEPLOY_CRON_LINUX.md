# Deploy — Cron Linux

Opcao mais simples para um servidor/VM proprio.

## 1. Instalar em um virtualenv dedicado

```bash
sudo mkdir -p /opt/racket-image-agent
sudo chown "$USER" /opt/racket-image-agent
git clone <url-do-repositorio> /opt/racket-image-agent/repo
cd /opt/racket-image-agent/repo/tools/racket-image-agent

python3 -m venv /opt/racket-image-agent/.venv
source /opt/racket-image-agent/.venv/bin/activate
pip install -e .
```

## 2. Credenciais e configuracao

```bash
sudo mkdir -p /opt/racket-image-agent/secrets
sudo chmod 700 /opt/racket-image-agent/secrets
# copie a chave da service account (NUNCA para dentro do repositorio git)
sudo cp /caminho/local/service-account.json /opt/racket-image-agent/secrets/service-account.json
sudo chmod 600 /opt/racket-image-agent/secrets/service-account.json

cp .env.example /opt/racket-image-agent/.env
# edite /opt/racket-image-agent/.env com os IDs reais e:
#   GOOGLE_APPLICATION_CREDENTIALS=/opt/racket-image-agent/secrets/service-account.json
#   STATE_FILE_PATH=/opt/racket-image-agent/data/state.json
#   REPORTS_DIR=/opt/racket-image-agent/data/relatorios
#   TIMEZONE=America/Sao_Paulo
```

Garanta que o timezone do sistema esteja correto (o cron do Linux usa o
timezone do sistema, nao o `TIMEZONE` do `.env`, que so afeta timestamps
internos do agente):

```bash
timedatectl set-timezone America/Sao_Paulo
```

## 3. Script wrapper

Crie `/opt/racket-image-agent/run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd /opt/racket-image-agent/repo/tools/racket-image-agent
set -a
source /opt/racket-image-agent/.env
set +a

exec /opt/racket-image-agent/.venv/bin/racket-image-agent --real-run
```

```bash
chmod +x /opt/racket-image-agent/run.sh
```

## 4. Crontab — toda segunda-feira as 08:00

```bash
crontab -e
```

Adicione (o sistema ja esta em `America/Sao_Paulo` pelo `timedatectl`
acima; se preferir nao depender do timezone do sistema, defina `CRON_TZ`
em crontabs que suportem essa variavel, ex.: cron do Debian/Ubuntu
modernos):

```cron
CRON_TZ=America/Sao_Paulo
0 8 * * 1 /opt/racket-image-agent/run.sh >> /opt/racket-image-agent/data/cron.log 2>&1
```

## 5. Teste manual antes de agendar

```bash
/opt/racket-image-agent/.venv/bin/racket-image-agent --dry-run
```
