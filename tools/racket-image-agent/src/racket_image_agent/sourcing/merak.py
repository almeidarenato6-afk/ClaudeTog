from __future__ import annotations

from .base import SiteSearchSource


class MerakSource(SiteSearchSource):
    """Fonte 2: Merak Beach Tennis.

    Assim como em `ProspinSource`, o template de busca precisa ser
    confirmado contra o site real durante a homologacao (URL oficial,
    endpoint de busca ou sitemap). Nao inventamos a URL definitiva aqui -
    preencha em `config/sources.json` (chave "merak.search_url_template")
    assim que confirmada.
    """

    name = "merak_beach_tennis"
    search_url_template = None
