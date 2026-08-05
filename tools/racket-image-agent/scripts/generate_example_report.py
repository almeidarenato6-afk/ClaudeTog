"""Script auxiliar (nao faz parte do pacote) usado uma unica vez para gerar
o relatorio de exemplo em `examples/`, com um catalogo sintetico cobrindo os
cinco status possiveis. Nao usa rede nem Google real - so fakes de teste."""
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PROJECT_ROOT / "src"))
sys.path.insert(0, str(PROJECT_ROOT))

from racket_image_agent.config import Config
from racket_image_agent.models import ImageCandidate, Product
from racket_image_agent.pipeline import Pipeline
from racket_image_agent.reporting import write_reports
from tests.fakes import FakeDriveClient, FakeHttpClient
from tests.helpers import make_jpeg

FOTOS_ROOT_ID = "fotos-ecommerce-root"


def rich_candidate(http, url, brand, model, role_hint, angle=None, bag_confirmed=False, color=(0, 0, 0)):
    http.add(url, make_jpeg(1600, 1600, color=color))
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


def main():
    drive = FakeDriveClient()
    http = FakeHttpClient()

    # 1) NOX AT10 Genius 2024 -> CONCLUIDO (5 fotos novas, inclusive bag)
    concluido = Product(brand="NOX", model="AT10 Genius", year="2024")
    concluido_candidates = [
        rich_candidate(http, "https://cdn.example.com/nox-capa.jpg", "NOX", "AT10 Genius", "capa", angle="inclinado", color=(10, 20, 30)),
        rich_candidate(http, "https://cdn.example.com/nox-verso.jpg", "NOX", "AT10 Genius", "verso", color=(200, 20, 30)),
        rich_candidate(http, "https://cdn.example.com/nox-detalhe.jpg", "NOX", "AT10 Genius", "detalhe", color=(20, 200, 30)),
        rich_candidate(http, "https://cdn.example.com/nox-complementar.jpg", "NOX", "AT10 Genius", "complementar", color=(20, 30, 200)),
        rich_candidate(http, "https://cdn.example.com/nox-bag.jpg", "NOX", "AT10 Genius", "bag", bag_confirmed=True, color=(200, 200, 30)),
    ]

    # 2) Bullpadel Vertex 04 -> PARCIAL (pasta com 2 fotos, so acha mais 1; sem bag confirmada)
    parcial = Product(brand="Bullpadel", model="Vertex 04", year="2024")
    drive.seed_folder(
        FOTOS_ROOT_ID,
        "Bullpadel Vertex 04 2024",
        [
            ("1 - Bullpadel Vertex 04 2024.jpg", make_jpeg(1600, 1600, color=(5, 5, 5))),
            ("3 - Bullpadel Vertex 04 2024.jpg", make_jpeg(1600, 1600, color=(250, 250, 250))),
        ],
    )
    parcial_candidates = [
        rich_candidate(http, "https://cdn.example.com/bull-verso.jpg", "Bullpadel", "Vertex 04", "verso", color=(90, 20, 30)),
    ]

    # 3) Head Speed Pro -> REVISAO (imagem encontrada, mas com confianca baixa)
    revisao = Product(brand="Head", model="Speed Pro", year="2024")
    fraca = ImageCandidate(
        url="https://exemplo-generico.com/foto-generica.jpg",
        page_url="https://exemplo-generico.com/pagina-generica",
        source_name="site_oficial_fabricante",
        role_hint="capa",
        angle="frontal",
        alt_text="Foto generica de raquete",
        page_text="Pagina sem mencao clara ao modelo especifico.",
        filename_hint="foto-generica.jpg",
    )
    http.add(fraca.url, make_jpeg(1600, 1600, color=(77, 88, 99)))

    # 4) Wilson Team 2.0 -> NAO_ENCONTRADO (nenhuma fonte teve resultado)
    nao_encontrado = Product(brand="Wilson", model="Team 2.0")

    # 5) Adidas Metalbone -> IGNORADO (pasta ja completa)
    ignorado = Product(brand="Adidas", model="Metalbone", year="2024")
    drive.seed_folder(
        FOTOS_ROOT_ID,
        "Adidas Metalbone 2024",
        [(f"{i} - Adidas Metalbone 2024.jpg", make_jpeg(1600, 1600, color=(i * 10, i * 5, i * 15))) for i in range(1, 6)],
    )

    candidates_by_model = {
        "AT10 Genius": concluido_candidates,
        "Vertex 04": parcial_candidates,
        "Speed Pro": [fraca],
        "Team 2.0": [],
        "Metalbone": [],
    }

    import racket_image_agent.pipeline as pipeline_module

    def fake_search_all_sources(product, http_client, config, robots_cache, logger_=None):
        return candidates_by_model.get(product.model, [])

    pipeline_module.search_all_sources = fake_search_all_sources
    pipeline_module.is_allowed = lambda *args, **kwargs: True

    config = Config()
    config.fotos_ecommerce_folder_id = FOTOS_ROOT_ID
    config.dry_run = False
    config.state_file_path = str(PROJECT_ROOT / "examples" / "_tmp_state.json")
    config.reports_dir = str(PROJECT_ROOT / "examples")
    config.match_confidence_threshold = 0.72

    pipeline = Pipeline(
        config,
        drive_client=drive,
        http_client=http,
        catalog=[concluido, parcial, revisao, nao_encontrado, ignorado],
    )
    report = pipeline.run()
    paths = write_reports(report, config.reports_dir)
    print(paths)

    for status_entry in report.products:
        print(status_entry.official_name, "->", status_entry.status)


if __name__ == "__main__":
    main()
