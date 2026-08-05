"""Interface comum das fontes de imagem e um fluxo generico de
"pesquisar -> abrir paginas de produto -> extrair candidatas" reutilizado
pelas fontes concretas (Prospin, Merak, fabricante).

As fontes concretas usam sitemaps/paginas de busca configuraveis (ver
`config/sources.json`) em vez de seletores fixos hardcoded: a estrutura HTML
real de cada site deve ser confirmada durante a homologacao (ver
`docs/HOMOLOGACAO_CHECKLIST.md`) antes da primeira execucao real, para nao
inventar URLs/seletores nao verificados.
"""
from __future__ import annotations

import abc
import logging
from typing import Dict, List, Optional
from urllib.parse import quote_plus

from ..models import ImageCandidate, Product
from .extractors import build_candidates
from .http_client import USER_AGENT, CircuitOpenError, RateLimitedClient
from .robots import is_allowed

logger = logging.getLogger(__name__)


class ImageSource(abc.ABC):
    name: str = "fonte"

    def __init__(self, http_client: RateLimitedClient, robots_cache: dict, config):
        self.http_client = http_client
        self.robots_cache = robots_cache
        self.config = config

    @abc.abstractmethod
    def search(self, product: Product) -> List[ImageCandidate]:
        ...

    def _fetch_html(self, url: str) -> Optional[str]:
        if not is_allowed(url, USER_AGENT, self.robots_cache):
            logger.info("bloqueado_por_robots", extra={"url": url, "fonte": self.name})
            return None
        try:
            response = self.http_client.get(url)
        except CircuitOpenError:
            logger.warning("circuito_aberto_ignorando_url", extra={"url": url, "fonte": self.name})
            return None
        except Exception as exc:  # falha temporaria de rede/site
            logger.warning("falha_ao_buscar_pagina", extra={"url": url, "erro": str(exc), "fonte": self.name})
            return None
        if response.status_code != 200:
            return None
        return response.text


def extract_product_links(html: str, base_url: str, max_links: int = 3) -> List[str]:
    from bs4 import BeautifulSoup
    from urllib.parse import urljoin

    soup = BeautifulSoup(html, "html.parser")
    links = []
    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"]
        if any(k in href.lower() for k in ("/produto", "/product", "/p/", "/raquete")):
            links.append(urljoin(base_url, href))
    # remove duplicatas preservando ordem
    seen = set()
    unique_links = []
    for link in links:
        if link not in seen:
            seen.add(link)
            unique_links.append(link)
    return unique_links[:max_links]


class SiteSearchSource(ImageSource):
    """Fonte generica: monta uma URL de busca a partir de um template,
    extrai links de produto da pagina de resultados e visita cada um para
    coletar imagens (JSON-LD / Open Graph / <img>)."""

    #: Template com "{query}" (URL-encoded) preenchido com "marca modelo".
    search_url_template: Optional[str] = None
    max_product_pages: int = 3

    def __init__(self, http_client, robots_cache, config, search_url_template: Optional[str] = None):
        super().__init__(http_client, robots_cache, config)
        if search_url_template is not None:
            self.search_url_template = search_url_template

    def build_query(self, product: Product) -> str:
        parts = [product.brand, product.model]
        if product.version:
            parts.append(product.version)
        return " ".join(p for p in parts if p)

    def search(self, product: Product) -> List[ImageCandidate]:
        if not self.search_url_template:
            logger.info("fonte_sem_template_configurado", extra={"fonte": self.name})
            return []

        query = quote_plus(self.build_query(product))
        search_url = self.search_url_template.format(query=query)

        html = self._fetch_html(search_url)
        if not html:
            return []

        product_links = extract_product_links(html, search_url, self.max_product_pages)
        candidates: List[ImageCandidate] = []
        for link in product_links:
            page_html = self._fetch_html(link)
            if not page_html:
                continue
            candidates.extend(build_candidates(page_html, link, self.name))
        return candidates
