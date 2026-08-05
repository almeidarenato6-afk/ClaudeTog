"""Verificacao de robots.txt por dominio, com cache em memoria por execucao."""
from __future__ import annotations

from typing import Dict, Optional
from urllib import robotparser
from urllib.parse import urlparse


def is_allowed(url: str, user_agent: str, robots_cache: Dict[str, Optional[robotparser.RobotFileParser]]) -> bool:
    parsed = urlparse(url)
    base = f"{parsed.scheme}://{parsed.netloc}"

    if base not in robots_cache:
        rp = robotparser.RobotFileParser()
        rp.set_url(f"{base}/robots.txt")
        try:
            rp.read()
        except Exception:
            rp = None
        robots_cache[base] = rp

    rp = robots_cache[base]
    if rp is None:
        # robots.txt indisponivel/ilegivel: por seguranca, nao bloqueia, mas
        # o rate limiting e o User-Agent identificavel continuam ativos.
        return True
    try:
        return rp.can_fetch(user_agent, url)
    except Exception:
        return True
