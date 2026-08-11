"""Orquestra a busca de imagens nas fontes, respeitando a ordem exigida:

1. prospin.com.br
2. Merak Beach Tennis
3. site oficial do fabricante

Cada fonte roda dentro de um try/except: uma fonte fora do ar nunca derruba
o processamento do produto - simplesmente passamos para a proxima fonte da
lista (e, no pior caso, o produto fica NAO_ENCONTRADO/REVISAO, registrado no
relatorio).
"""
from __future__ import annotations

import logging
from typing import List

from ..models import ImageCandidate, Product
from .manufacturer import ManufacturerSource
from .merak import MerakSource
from .prospin import ProspinSource
from .site_config import load_sources_config

logger = logging.getLogger(__name__)

# Cobertura minima de papeis para considerarmos que ja temos material
# suficiente e podermos parar de acionar fontes adicionais.
_SUFFICIENT_ROLES = {"capa", "verso", "detalhe"}


def _has_enough_role_coverage(candidates: List[ImageCandidate]) -> bool:
    roles = {c.role_hint for c in candidates}
    return _SUFFICIENT_ROLES.issubset(roles) or len(candidates) >= 5


def build_sources(http_client, config, robots_cache: dict):
    overrides = load_sources_config()
    prospin = ProspinSource(
        http_client, robots_cache, config,
        search_url_template=overrides.get("prospin", {}).get("search_url_template"),
    )
    merak = MerakSource(
        http_client, robots_cache, config,
        search_url_template=overrides.get("merak_beach_tennis", {}).get("search_url_template"),
    )
    manufacturer = ManufacturerSource(http_client, robots_cache, config)
    return [prospin, merak, manufacturer]


def search_all_sources(product: Product, http_client, config, robots_cache: dict, logger_=logger) -> List[ImageCandidate]:
    all_candidates: List[ImageCandidate] = []
    for source in build_sources(http_client, config, robots_cache):
        try:
            candidates = source.search(product)
            all_candidates.extend(candidates)
        except Exception as exc:  # nunca deixa uma fonte derrubar o lote
            logger_.warning("fonte_falhou", extra={"fonte": source.name, "erro": str(exc)})
        if _has_enough_role_coverage(all_candidates):
            break
    return all_candidates
