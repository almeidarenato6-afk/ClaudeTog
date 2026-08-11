# Checklist de homologacao (antes da primeira execucao real)

Use este checklist antes de rodar `--real-run` pela primeira vez em
producao. Nada aqui e opcional para o primeiro uso real.

## Credenciais e permissoes

- [ ] Service account (ou usuario OAuth) criada e `GOOGLE_CREDENTIALS_JSON`
      (ou `GOOGLE_APPLICATION_CREDENTIALS`) configurado via secret
      manager/variavel de ambiente — nunca em arquivo versionado no git.
- [ ] A pasta raiz do Drive (ou Shared Drive) foi compartilhada com a
      service account com papel Editor/Content Manager.
- [ ] A planilha de catalogo foi compartilhada com a service account
      (Leitor e suficiente).
- [ ] `GOOGLE_DRIVE_ROOT_FOLDER_ID` (ou `FOTOS_ECOMMERCE_FOLDER_ID`) aponta
      para o local correto e foi validado com `--dry-run` (o relatorio deve
      listar a pasta "Fotos E-commerce" sem erro de "pasta nao encontrada").
- [ ] `CATALOG_SPREADSHEET_ID` e `CATALOG_RANGE` apontam para a aba/faixa
      correta da planilha de raquetes.

## Fontes de imagem

- [ ] `config/sources.json`: template de busca do prospin.com.br confirmado
      contra o site real (endpoint de busca/sitemap/API), nao apenas o
      placeholder padrao do codigo.
- [ ] `config/sources.json`: template de busca da Merak Beach Tennis
      preenchido e confirmado (o placeholder inicial e `null`, ou seja, essa
      fonte fica inativa ate ser configurada).
- [ ] `config/manufacturer_domains.json`: dominios oficiais das marcas
      priorizadas para o primeiro lote preenchidos e confirmados
      manualmente (nenhum dominio foi "chutado").
- [ ] `robots.txt` de cada dominio configurado foi revisado manualmente uma
      vez (o agente respeita automaticamente, mas vale confirmar que as
      paginas de produto nao estao bloqueadas).

## Regras de negocio

- [ ] `MATCH_CONFIDENCE_THRESHOLD` revisado com um lote de amostra (rodar
      `--dry-run` em ~10 produtos e conferir se o numero de REVISAO esta
      razoavel — nem alto demais, nem baixo demais).
- [ ] `MIN_IMAGE_SIDE` / `PREFERRED_IMAGE_SIDE` conferem com o padrao atual
      da loja.
- [ ] Nome oficial gerado (`build_official_name`) foi conferido para pelo
      menos 3 produtos de marcas diferentes — sem caracteres estranhos, sem
      duplicacao de marca no modelo.

## Execucao seca (dry-run)

- [ ] `racket-image-agent --dry-run` executado com o catalogo real completo.
- [ ] Relatorio (`data/relatorios/execution_*.md`) revisado por um humano:
      contagem de CONCLUIDO / PARCIAL / REVISAO / NAO_ENCONTRADO / IGNORADO
      faz sentido para o tamanho do catalogo.
- [ ] Nenhuma pendencia de "marca d'agua suspeita" ou "resolucao baixa" foi
      ignorada sem revisao manual da imagem referenciada.
- [ ] Pendencias de "bag sem confirmacao" revisadas — confirmar que
      nenhuma raquete que realmente vem com bag ficou sem a Foto 5 por
      excesso de cautela do heuristico (ajustar `_INCLUSION_HINTS` em
      `sourcing/extractors.py` se necessario).

## Idempotencia

- [ ] `--dry-run` executado duas vezes seguidas: o segundo relatorio nao
      lista nenhum produto como "novo" que a primeira execucao ja teria
      processado (comparar as contagens de IGNORADO/CONCLUIDO).
- [ ] Testes automatizados (`pytest`) passando 100% localmente, incluindo
      os casos de idempotencia (`tests/test_pipeline.py`).

## Primeira execucao real (lote pequeno)

- [ ] Rodar `--real-run` primeiro contra um subconjunto pequeno do catalogo
      (ex.: limitar temporariamente a planilha/range a 3-5 produtos) antes
      do catalogo completo.
- [ ] Conferir manualmente no Drive: pasta criada com nome correto, 5
      arquivos (ou menos, com pendencia registrada) com nomenclatura exata
      `N - Nome Oficial.jpg`.
- [ ] Conferir que a Foto 1 e realmente uma capa frontal/inclinada
      adequada (nao um detalhe ou a bag por engano).
- [ ] Conferir que nenhuma imagem com preco/selo/promocao sobreposto foi
      aceita.

## Observabilidade e agendamento

- [ ] Logs estruturados (JSON) visiveis no destino escolhido (Cloud
      Logging / stdout do GitHub Actions / arquivo de log do cron).
- [ ] Alertas configurados para falhas recorrentes (opcional, mas
      recomendado para Cloud Run + Cloud Scheduler).
- [ ] Agendamento configurado e testado com um disparo manual antes de
      confiar no cron automatico (`gcloud scheduler jobs run ...` /
      `workflow_dispatch` / execucao manual do `run.sh`).

Somente apos todos os itens acima marcados o agendamento automatico deve
ficar ativo com `DRY_RUN=false`.
