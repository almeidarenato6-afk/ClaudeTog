import requests

from racket_image_agent.sourcing.http_client import CircuitOpenError, RateLimitedClient


class _FakeSession:
    """Simula falhas temporarias de um site: as N primeiras chamadas para uma
    URL falham, depois passam a funcionar."""

    def __init__(self, fail_times: int = 0, status_code: int = 200):
        self.fail_times = fail_times
        self.status_code = status_code
        self.calls = 0

    def get(self, url, headers=None, timeout=None, **kwargs):
        self.calls += 1
        if self.calls <= self.fail_times:
            raise requests.exceptions.ConnectionError("falha temporaria simulada")
        return _FakeResponse(self.status_code)


class _AlwaysFailSession:
    def __init__(self):
        self.calls = 0

    def get(self, url, headers=None, timeout=None, **kwargs):
        self.calls += 1
        raise requests.exceptions.ConnectionError("site fora do ar")


class _FakeResponse:
    def __init__(self, status_code=200, content=b"ok"):
        self.status_code = status_code
        self.content = content
        self.text = content.decode() if isinstance(content, bytes) else content


def _client(session, **kwargs):
    return RateLimitedClient(
        min_interval_seconds=0.0,
        max_retries=kwargs.pop("max_retries", 3),
        backoff_base=1.0,
        failure_threshold=kwargs.pop("failure_threshold", 5),
        circuit_cooldown_seconds=kwargs.pop("circuit_cooldown_seconds", 300.0),
        session=session,
        sleep_fn=lambda _seconds: None,
        clock=_FakeClock(),
        **kwargs,
    )


class _FakeClock:
    def __init__(self):
        self.now = 0.0

    def __call__(self):
        self.now += 0.001
        return self.now


def test_transient_site_failure_recovers_after_retries():
    session = _FakeSession(fail_times=2)
    client = _client(session, max_retries=3)

    response = client.get("https://example.com/produto")

    assert response.status_code == 200
    assert session.calls == 3  # 2 falhas + 1 sucesso


def test_persistent_failure_raises_after_exhausting_retries():
    session = _FakeSession(fail_times=99)
    client = _client(session, max_retries=3)

    try:
        client.get("https://example.com/produto")
        assert False, "deveria ter levantado excecao"
    except requests.exceptions.ConnectionError:
        pass

    assert session.calls == 3


def test_circuit_breaker_opens_after_failure_threshold_and_blocks_subsequent_calls():
    session = _AlwaysFailSession()
    client = _client(session, max_retries=1, failure_threshold=2)

    for _ in range(2):
        try:
            client.get("https://falho.example.com/produto")
        except requests.exceptions.ConnectionError:
            pass

    calls_before_circuit_check = session.calls
    try:
        client.get("https://falho.example.com/produto")
        assert False, "deveria ter recusado a chamada com circuito aberto"
    except CircuitOpenError:
        pass

    # o circuito aberto nao deve ter gerado uma nova tentativa de rede
    assert session.calls == calls_before_circuit_check


def test_circuit_breaker_is_per_domain():
    session = _AlwaysFailSession()
    client = _client(session, max_retries=1, failure_threshold=1)

    try:
        client.get("https://dominio-com-problema.example.com/x")
    except requests.exceptions.ConnectionError:
        pass

    # outro dominio nao deve ser afetado pelo circuito do primeiro
    try:
        client.get("https://outro-dominio.example.com/y")
    except requests.exceptions.ConnectionError:
        pass
    except CircuitOpenError:
        assert False, "circuito de um dominio nao deveria afetar outro dominio"
