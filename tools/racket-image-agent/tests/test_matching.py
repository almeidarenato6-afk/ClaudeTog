from racket_image_agent.matching import compute_confidence, meets_threshold
from racket_image_agent.models import ImageCandidate, Product


def _product():
    return Product(brand="Head", model="Speed Pro", year="2024", color="Preto")


def test_strong_match_scores_above_default_threshold():
    product = _product()
    candidate = ImageCandidate(
        url="https://www.prospin.com.br/raquete-head-speed-pro/imagem-1.jpg",
        page_url="https://www.prospin.com.br/head-raquete-speed-pro-2024",
        source_name="prospin",
        alt_text="Raquete Head Speed Pro 2024 Preto",
        page_text="Raquete Head Speed Pro 2024 na cor Preto, disponivel na Prospin.",
        filename_hint="head-speed-pro-2024.jpg",
    )
    score = compute_confidence(product, candidate)
    assert score > 0.7
    assert meets_threshold(score, 0.72)


def test_weak_match_scores_below_default_threshold():
    product = _product()
    candidate = ImageCandidate(
        url="https://example.com/qualquer-produto.jpg",
        page_url="https://example.com/outro-produto-generico",
        source_name="desconhecida",
        alt_text="Bola de beach tennis",
        page_text="Pagina generica sobre outro produto qualquer.",
        filename_hint="outro-produto.jpg",
    )
    score = compute_confidence(product, candidate)
    assert not meets_threshold(score, 0.72)


def test_score_is_bounded_between_zero_and_one():
    product = _product()
    candidate = ImageCandidate(
        url="https://www.prospin.com.br/head-speed-pro.jpg",
        page_url="https://www.prospin.com.br/head-speed-pro-2024-preto",
        source_name="prospin",
        alt_text="Head Speed Pro 2024 Preto",
        page_text="Head Speed Pro 2024 Preto Head Speed Pro 2024 Preto",
        filename_hint="head-speed-pro-2024-preto.jpg",
    )
    score = compute_confidence(product, candidate)
    assert 0.0 <= score <= 1.0


def test_visual_score_contributes_when_provided():
    product = _product()
    candidate = ImageCandidate(
        url="https://example.com/img.jpg",
        page_url="https://example.com/pagina",
        source_name="desconhecida",
    )
    weights = {
        "page_text": 0.15, "filename": 0.1, "alt_text": 0.1, "brand": 0.15,
        "model": 0.15, "year": 0.05, "color": 0.05, "page_context": 0.05, "visual": 0.2,
    }
    score_without_visual = compute_confidence(product, candidate, weights=dict(weights), visual_score=None)
    score_with_visual = compute_confidence(product, candidate, weights=dict(weights), visual_score=1.0)
    assert score_with_visual > score_without_visual
