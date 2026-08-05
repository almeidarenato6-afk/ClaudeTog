FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

COPY pyproject.toml requirements.txt README.md ./
COPY src ./src
COPY config ./config

RUN pip install --upgrade pip && pip install .

RUN useradd --create-home --uid 10001 agent \
    && mkdir -p /app/data/relatorios \
    && chown -R agent:agent /app
USER agent

ENV DRY_RUN=true \
    STATE_FILE_PATH=/app/data/state.json \
    REPORTS_DIR=/app/data/relatorios \
    LOG_LEVEL=INFO

ENTRYPOINT ["racket-image-agent"]
CMD ["--dry-run"]
