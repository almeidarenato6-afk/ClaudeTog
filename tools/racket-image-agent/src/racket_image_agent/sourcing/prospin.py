from __future__ import annotations

from .base import SiteSearchSource


class ProspinSource(SiteSearchSource):
    """Fonte 1 (maior prioridade): https://www.prospin.com.br

    O template de busca abaixo segue o padrao comum de busca de e-commerces
    (Nuvemshop, VTEX, etc: "?q=..."). CONFIRME o template real do site
    (endpoint de busca, ou prefira o sitemap.xml / API de busca se
    disponivel) durante a homologacao antes de rodar em modo real - ver
    `docs/HOMOLOGACAO_CHECKLIST.md`.
    """

    name = "prospin"
    search_url_template = "https://www.prospin.com.br/busca?q={query}"
