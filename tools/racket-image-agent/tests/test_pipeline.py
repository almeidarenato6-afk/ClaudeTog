from racket_image_agent.config import Config
from racket_image_agent.models import ImageCandidate, Product, ProductStatus
from racket_image_agent.pipeline import Pipeline

from .fakes import FakeDriveClient, FakeHttpClient
from .helpers import make_jpeg

FOTOS_ROOT_ID = "fotos-ecommerce-root"


def _make_config(tmp_path, dry_run: bool) -> Config:
    config = Config()
    config.fotos_ecommerce_folder_id = FOTOS_ROOT_ID
    config.dry_run = dry_run
    config.state_file_path = str(tmp_path / "state.json")
    config.reports_dir = str(tmp_path / "relatorios")
    config.match_confidence_threshold = 0.72
    config.min_image_side = 1000
    config.preferred_image_side = 1500
    return config


def _rich_candidate(http_client, url, brand, model, role_hint, angle=None, bag_confirmed=False, color=(100, 150, 200)):
    """Cria uma ImageCandidate com metadados fortes o bastante para passar
    no limiar de confianca padrao, e registra bytes de imagem reais e
    unicos (para nao colidir na deduplicacao) no FakeHttpClient."""
    data = make_jpeg(1600, 1600, color=color)
    http_client.add(url, data)
    return ImageCandidate(
        url=url,
        page_url=f"https://www.prospin.com.br/{brand}-{model}".lower().replace(" ", "-"),
        source_name="prospin",
        role_hint=role_hint,
        angle=angle,
        bag_confirmed=bag_confirmed,
        alt_text=f"{brand} {model} foto produto",
        page_text=f"Raquete {brand} {model} completa, disponivel na loja.",
        filename_hint=f"{brand} {model}".lower().replace(" ", "-") + ".jpg",
    )


def _full_candidate_set(http_client, brand, model, url_prefix):
    return [
        _rich_candidate(http_client, f"{url_prefix}-capa.jpg", brand, model, "capa", angle="inclinado", color=(10, 20, 30)),
        _rich_candidate(http_client, f"{url_prefix}-verso.jpg", brand, model, "verso", color=(200, 20, 30)),
        _rich_candidate(http_client, f"{url_prefix}-detalhe.jpg", brand, model, "detalhe", color=(20, 200, 30)),
        _rich_candidate(http_client, f"{url_prefix}-complementar.jpg", brand, model, "complementar", color=(20, 30, 200)),
        _rich_candidate(http_client, f"{url_prefix}-bag.jpg", brand, model, "bag", bag_confirmed=True, color=(200, 200, 30)),
    ]


def _patch_search(monkeypatch, candidates_by_model):
    def fake_search_all_sources(product, http_client, config, robots_cache, logger_=None):
        return candidates_by_model.get(product.model, [])

    monkeypatch.setattr("racket_image_agent.pipeline.search_all_sources", fake_search_all_sources)


def test_new_model_is_detected_and_fully_processed(tmp_path, monkeypatch):
    product = Product(brand="Head", model="Speed Pro 2024")
    drive = FakeDriveClient()
    http = FakeHttpClient()
    candidates = _full_candidate_set(http, "Head", "Speed Pro 2024", "https://cdn.example.com/head-speed-pro")
    _patch_search(monkeypatch, {"Speed Pro 2024": candidates})

    config = _make_config(tmp_path, dry_run=False)
    pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])

    report = pipeline.run()

    assert len(report.products) == 1
    entry = report.products[0]
    assert entry.status == ProductStatus.CONCLUIDO.value
    assert entry.folder_created is True
    assert len(entry.images_saved) == 5
    assert drive.create_folder_calls == [(FOTOS_ROOT_ID, entry.official_name)]


def test_pipeline_is_idempotent_across_two_runs(tmp_path, monkeypatch):
    product = Product(brand="Head", model="Speed Pro 2024")
    drive = FakeDriveClient()
    http = FakeHttpClient()
    candidates = _full_candidate_set(http, "Head", "Speed Pro 2024", "https://cdn.example.com/head-speed-pro")
    _patch_search(monkeypatch, {"Speed Pro 2024": candidates})

    config = _make_config(tmp_path, dry_run=False)

    first_pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])
    first_report = first_pipeline.run()
    assert first_report.products[0].status == ProductStatus.CONCLUIDO.value
    assert len(drive.upload_calls) == 5
    assert len(drive.create_folder_calls) == 1

    # segunda "execucao" (novo processo): novo Pipeline, mesmo state em disco
    # e mesmo Drive (simulado) - nao deve criar pasta nem enviar arquivos de novo.
    second_pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])
    second_report = second_pipeline.run()

    assert second_report.products[0].status == ProductStatus.IGNORADO.value
    assert len(drive.upload_calls) == 5  # inalterado
    assert len(drive.create_folder_calls) == 1  # inalterado


def test_creates_folder_when_absent(tmp_path, monkeypatch):
    product = Product(brand="Wilson", model="Team 2.0")
    drive = FakeDriveClient()
    http = FakeHttpClient()
    candidates = _full_candidate_set(http, "Wilson", "Team 2.0", "https://cdn.example.com/wilson-team")
    _patch_search(monkeypatch, {"Team 2.0": candidates})

    config = _make_config(tmp_path, dry_run=False)
    pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])
    pipeline.run()

    assert len(drive.create_folder_calls) == 1


def test_complete_folder_is_classified_as_ignored_without_network_calls(tmp_path, monkeypatch):
    product = Product(brand="Wilson", model="Team 2.0")
    official_name = "Wilson Team 2.0"
    drive = FakeDriveClient()
    files = [(f"{i} - {official_name}.jpg", make_jpeg(1600, 1600, color=(i * 10, i * 20, i * 30))) for i in range(1, 6)]
    drive.seed_folder(FOTOS_ROOT_ID, official_name, files)

    http = FakeHttpClient()
    search_calls = []

    def fake_search_all_sources(product_, http_client, config, robots_cache, logger_=None):
        search_calls.append(product_.model)
        return []

    monkeypatch.setattr("racket_image_agent.pipeline.search_all_sources", fake_search_all_sources)

    config = _make_config(tmp_path, dry_run=False)
    pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])
    report = pipeline.run()

    assert report.products[0].status == ProductStatus.IGNORADO.value
    assert search_calls == []  # nao deveria nem tentar buscar fontes
    assert http.calls == []
    assert drive.create_folder_calls == []
    assert drive.upload_calls == []


def test_incomplete_folder_is_completed_without_touching_existing_slots(tmp_path, monkeypatch):
    product = Product(brand="Wilson", model="Team 2.0")
    official_name = "Wilson Team 2.0"
    drive = FakeDriveClient()
    existing = [
        (f"1 - {official_name}.jpg", make_jpeg(1600, 1600, color=(5, 5, 5))),
        (f"3 - {official_name}.jpg", make_jpeg(1600, 1600, color=(250, 250, 250))),
    ]
    drive.seed_folder(FOTOS_ROOT_ID, official_name, existing)

    http = FakeHttpClient()
    candidates = [
        _rich_candidate(http, "https://cdn.example.com/verso.jpg", "Wilson", "Team 2.0", "verso", color=(200, 20, 30)),
        _rich_candidate(http, "https://cdn.example.com/complementar.jpg", "Wilson", "Team 2.0", "complementar", color=(20, 30, 200)),
        _rich_candidate(http, "https://cdn.example.com/bag.jpg", "Wilson", "Team 2.0", "bag", bag_confirmed=True, color=(200, 200, 30)),
    ]
    _patch_search(monkeypatch, {"Team 2.0": candidates})

    config = _make_config(tmp_path, dry_run=False)
    pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])
    report = pipeline.run()

    entry = report.products[0]
    assert entry.status == ProductStatus.CONCLUIDO.value
    saved_names = set(entry.images_saved)
    assert saved_names == {
        f"2 - {official_name}.jpg",
        f"4 - {official_name}.jpg",
        f"5 - {official_name}.jpg",
    }
    # os slots 1 e 3 (ja existentes) nunca sao reenviados
    for filename, _ in existing:
        assert filename not in entry.images_saved


def test_dry_run_never_creates_folders_or_uploads_files(tmp_path, monkeypatch):
    product = Product(brand="Head", model="Speed Pro 2024")
    drive = FakeDriveClient()
    http = FakeHttpClient()
    candidates = _full_candidate_set(http, "Head", "Speed Pro 2024", "https://cdn.example.com/head-speed-pro")
    _patch_search(monkeypatch, {"Speed Pro 2024": candidates})

    config = _make_config(tmp_path, dry_run=True)
    pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[product])
    report = pipeline.run()

    entry = report.products[0]
    assert drive.create_folder_calls == []
    assert drive.upload_calls == []
    assert all(name.startswith("(dry-run)") for name in entry.images_saved)
    assert len(entry.images_saved) == 5


def test_google_api_failure_on_one_product_does_not_abort_the_batch(tmp_path, monkeypatch):
    ok_product = Product(brand="Wilson", model="Team 2.0")
    failing_product = Product(brand="Head", model="Speed Pro 2024")

    class FlakyDriveClient(FakeDriveClient):
        def __init__(self, fail_for_parent_and_name):
            super().__init__()
            self.fail_for = fail_for_parent_and_name

        def find_folder_by_name(self, parent_id, name):
            if (parent_id, name) == self.fail_for:
                raise RuntimeError("Google Drive API indisponivel (simulado)")
            return super().find_folder_by_name(parent_id, name)

    drive = FlakyDriveClient((FOTOS_ROOT_ID, "Head Speed Pro 2024"))
    http = FakeHttpClient()
    candidates = _full_candidate_set(http, "Wilson", "Team 2.0", "https://cdn.example.com/wilson-team")
    _patch_search(monkeypatch, {"Team 2.0": candidates, "Speed Pro 2024": []})

    config = _make_config(tmp_path, dry_run=False)
    pipeline = Pipeline(config, drive_client=drive, http_client=http, catalog=[failing_product, ok_product])
    report = pipeline.run()

    assert len(report.products) == 2

    failing_entry = next(e for e in report.products if e.official_name == "Head Speed Pro 2024")
    assert failing_entry.status == ProductStatus.NAO_ENCONTRADO.value
    assert failing_entry.errors

    ok_entry = next(e for e in report.products if e.official_name == "Wilson Team 2.0")
    assert ok_entry.status == ProductStatus.CONCLUIDO.value
    assert not ok_entry.errors
