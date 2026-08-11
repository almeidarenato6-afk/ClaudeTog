"""Cliente HTTP com identificacao propria, rate limiting por dominio, retry
com backoff exponencial, timeout por requisicao e um circuit breaker simples
por dominio.

O `sleep_fn` e o `clock` sao injetaveis para permitir testes deterministicos
sem esperas reais.
"""
from __future__ import annotations

import logging
import time
from dataclasses import dataclass, field
from typing import Callable, Dict, Optional
from urllib.parse import urlparse

import requests

logger = logging.getLogger(__name__)

USER_AGENT = "TogPlayRacketImageAgent/1.0 (+contato: almeidarenato6@gmail.com)"


class CircuitOpenError(Exception):
    """Levantado quando o circuito de um dominio esta aberto (muitas falhas
    recentes) e a requisicao e recusada sem nem tentar a rede."""


@dataclass
class DomainState:
    last_request_ts: float = 0.0
    consecutive_failures: int = 0
    circuit_open_until: float = 0.0


class RateLimitedClient:
    def __init__(
        self,
        min_interval_seconds: float = 2.0,
        timeout_seconds: float = 15.0,
        max_retries: int = 3,
        backoff_base: float = 1.5,
        failure_threshold: int = 5,
        circuit_cooldown_seconds: float = 300.0,
        session: Optional[requests.Session] = None,
        sleep_fn: Callable[[float], None] = time.sleep,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self.min_interval_seconds = min_interval_seconds
        self.timeout_seconds = timeout_seconds
        self.max_retries = max_retries
        self.backoff_base = backoff_base
        self.failure_threshold = failure_threshold
        self.circuit_cooldown_seconds = circuit_cooldown_seconds
        self.session = session or requests.Session()
        self.sleep_fn = sleep_fn
        self.clock = clock
        self._domains: Dict[str, DomainState] = {}

    def _domain_state(self, url: str) -> DomainState:
        domain = urlparse(url).netloc
        return self._domains.setdefault(domain, DomainState())

    def get(self, url: str, **kwargs) -> requests.Response:
        state = self._domain_state(url)
        now = self.clock()
        if now < state.circuit_open_until:
            raise CircuitOpenError(f"circuito aberto para {urlparse(url).netloc}")

        wait = state.last_request_ts + self.min_interval_seconds - now
        if wait > 0:
            self.sleep_fn(wait)

        headers = kwargs.pop("headers", {}) or {}
        headers.setdefault("User-Agent", USER_AGENT)

        last_exc: Optional[Exception] = None
        for attempt in range(1, self.max_retries + 1):
            try:
                response = self.session.get(
                    url, headers=headers, timeout=self.timeout_seconds, **kwargs
                )
                state.last_request_ts = self.clock()
                if response.status_code >= 500:
                    raise requests.HTTPError(f"HTTP {response.status_code} em {url}")
                state.consecutive_failures = 0
                return response
            except requests.RequestException as exc:
                last_exc = exc
                state.consecutive_failures += 1
                logger.warning(
                    "falha_requisicao", extra={"url": url, "tentativa": attempt, "erro": str(exc)}
                )
                if state.consecutive_failures >= self.failure_threshold:
                    state.circuit_open_until = self.clock() + self.circuit_cooldown_seconds
                    logger.error("circuito_aberto", extra={"dominio": urlparse(url).netloc})
                if attempt < self.max_retries:
                    self.sleep_fn(self.backoff_base**attempt)

        assert last_exc is not None
        raise last_exc
