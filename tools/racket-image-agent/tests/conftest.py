"""Configuracao compartilhada de testes.

Os testes unitarios/de integracao nunca devem depender de acesso real a
rede (nem para robots.txt): por padrao, `is_allowed` e substituido por uma
versao que sempre permite, evitando chamadas reais de DNS/HTTP durante a
suite. O comportamento real de robots.txt fica coberto por
`sourcing/robots.py` sendo simples o bastante para revisao direta e por uso
manual/homologacao (ver docs/HOMOLOGACAO_CHECKLIST.md).
"""
import pytest


@pytest.fixture(autouse=True)
def _no_real_network_for_robots_checks(monkeypatch):
    def _always_allowed(url, user_agent, robots_cache):
        return True

    monkeypatch.setattr("racket_image_agent.pipeline.is_allowed", _always_allowed)
    monkeypatch.setattr("racket_image_agent.sourcing.base.is_allowed", _always_allowed)
