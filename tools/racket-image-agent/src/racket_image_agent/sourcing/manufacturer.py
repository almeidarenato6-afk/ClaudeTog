from __future__ import annotations

import logging
from typing import Dict, List, Optional
from urllib.parse import quote_plus

from ..models import ImageCandidate, Product
from .base import ImageSource, extract_product_links
from .extractors import build_candidates
from .site_config import load_manufacturer_domains

logger = logging.getLogger(__name__)


class ManufacturerSource(ImageSource):
    """Fonte 3: site oficial do fabricante da marca.

    O dominio oficial de cada marca deve ser confirmado e preenchido em
    `config/manufacturer_domains.json` (nao inventamos URLs de fabricante
    aqui - ficam como placeholder `null` ate serem validadas). Marcas sem
    dominio configurado sao puladas com um aviso no log; isso nao e um erro
    fatal, apenas significa que essa fonte ainda nao esta disponivel para a
    marca em questao.
    """

    name = "site_oficial_fabricante"

    def __init__(
        self,
        http_client,
        robots_cache,
        config,
        domains: Optional[Dict[str, Optional[str]]] = None,
    ):
        super().__init__(http_client, robots_cache, config)
        self.domains = domains if domains is not None else load_manufacturer_domains()

    def search(self, product: Product) -> List[ImageCandidate]:
        domain = self.domains.get(product.brand)
        if not domain:
            logger.info("dominio_fabricante_nao_configurado", extra={"marca": product.brand})
            return []

        query = quote_plus(f"{product.model} {product.version or ''}".strip())
        search_url = f"{domain.rstrip('/')}/search?q={query}"

        html = self._fetch_html(search_url)
        if not html:
            return []

        product_links = extract_product_links(html, search_url)
        candidates: List[ImageCandidate] = []
        for link in product_links:
            page_html = self._fetch_html(link)
            if not page_html:
                continue
            candidates.extend(build_candidates(page_html, link, self.name))
        return candidates
