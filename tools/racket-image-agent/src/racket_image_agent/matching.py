"""Score de confianca de correspondencia entre uma imagem candidata e o
produto (raquete) que estamos tentando fotografar.

Combina evidencias textuais (texto da pagina, nome do arquivo, alt text,
marca, modelo, ano, cor, contexto da URL da pagina) e, quando disponivel,
uma classificacao visual externa (0-1) injetada pelo chamador. Abaixo do
limiar configurado, a imagem fica em status REVISAO e nao e usada
automaticamente.
"""
from __future__ import annotations

from typing import Dict, Optional

from .models import ImageCandidate, Product

DEFAULT_WEIGHTS: Dict[str, float] = {
    "page_text": 0.20,
    "filename": 0.10,
    "alt_text": 0.15,
    "brand": 0.20,
    "model": 0.20,
    "year": 0.05,
    "color": 0.05,
    "page_context": 0.05,
    "visual": 0.00,
}


def _contains_normalized(haystack: str, needle: str) -> bool:
    if not haystack or not needle:
        return False
    return needle.strip().lower() in haystack.strip().lower()


def compute_confidence(
    product: Product,
    candidate: ImageCandidate,
    weights: Optional[Dict[str, float]] = None,
    visual_score: Optional[float] = None,
) -> float:
    weights = dict(weights or DEFAULT_WEIGHTS)

    if visual_score is None:
        redistribute = weights.pop("visual", 0.0)
        if redistribute and weights:
            share = redistribute / len(weights)
            for key in weights:
                weights[key] += share

    combined_meta = f"{candidate.page_text} {candidate.alt_text}"

    scores = {
        "page_text": 1.0 if _contains_normalized(candidate.page_text, product.model) else 0.0,
        "filename": 1.0 if _contains_normalized(candidate.filename_hint, product.model) else 0.0,
        "alt_text": 1.0 if _contains_normalized(candidate.alt_text, product.model) else 0.0,
        "brand": 1.0 if _contains_normalized(combined_meta, product.brand) else 0.0,
        "model": 1.0 if _contains_normalized(combined_meta, product.model) else 0.0,
        "year": 1.0 if (not product.year or _contains_normalized(candidate.page_text, str(product.year))) else 0.0,
        "color": 1.0 if (not product.color or _contains_normalized(combined_meta, str(product.color))) else 0.0,
        "page_context": 1.0
        if _contains_normalized(candidate.page_url, product.brand.split()[0] if product.brand else "")
        else 0.0,
    }
    if "visual" in weights:
        scores["visual"] = visual_score if visual_score is not None else 0.0

    total = sum(scores.get(key, 0.0) * weight for key, weight in weights.items())
    return round(min(total, 1.0), 4)


def meets_threshold(score: float, threshold: float) -> bool:
    return score >= threshold
