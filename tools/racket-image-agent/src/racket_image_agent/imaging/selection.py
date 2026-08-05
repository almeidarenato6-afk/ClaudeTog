"""Selecao das 5 fotos finais, na ordem exigida:

1. Capa: frente, preferencialmente inclinada; senao frontal em pe.
2. Angulo alternativo ou verso.
3. Detalhe relevante.
4. Outro angulo/detalhe complementar.
5. Bag/capa/estojo - somente se houver confirmacao de que acompanha o
   produto. Sem confirmacao, o slot fica vazio (pendencia), nunca e usada
   uma imagem que possa induzir o cliente a erro.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional, Set

from ..models import ImageCandidate


@dataclass
class SelectionResult:
    # Sempre 5 posicoes; None quando o slot nao pode ser preenchido.
    ordered_images: List[Optional[ImageCandidate]] = field(default_factory=lambda: [None] * 5)
    pendencies: List[str] = field(default_factory=list)


def _best(pool: List[ImageCandidate]) -> Optional[ImageCandidate]:
    if not pool:
        return None
    return max(pool, key=lambda c: c.confidence)


def _pool_for_role(candidates: List[ImageCandidate], role: str, used: Set[str]) -> List[ImageCandidate]:
    return [c for c in candidates if c.role_hint == role and c.url not in used]


def select_five_photos(candidates: List[ImageCandidate]) -> SelectionResult:
    result = SelectionResult()
    used: Set[str] = set()

    # Foto 1: capa
    capa_pool = _pool_for_role(candidates, "capa", used)
    inclined_pool = [c for c in capa_pool if c.angle == "inclinado"]
    foto1 = _best(inclined_pool) or _best(capa_pool)
    if not foto1:
        frontal_pool = [c for c in candidates if c.angle == "frontal" and c.url not in used]
        foto1 = _best(frontal_pool)
    if foto1:
        used.add(foto1.url)

    # Foto 2: verso / angulo alternativo
    foto2 = _best(_pool_for_role(candidates, "verso", used))
    if foto2:
        used.add(foto2.url)

    # Foto 3: detalhe
    foto3 = _best(_pool_for_role(candidates, "detalhe", used))
    if foto3:
        used.add(foto3.url)

    # Foto 4: complementar (reaproveita "detalhe"/"other" restantes se preciso)
    foto4 = _best(_pool_for_role(candidates, "complementar", used))
    if not foto4:
        remaining = [
            c for c in candidates if c.role_hint in ("detalhe", "other") and c.url not in used
        ]
        foto4 = _best(remaining)
    if foto4:
        used.add(foto4.url)

    # Foto 5: bag/estojo, somente com confirmacao
    bag_pool = [c for c in candidates if c.role_hint == "bag" and c.url not in used]
    confirmed_bag_pool = [c for c in bag_pool if c.bag_confirmed]
    foto5 = _best(confirmed_bag_pool)
    if foto5:
        used.add(foto5.url)
    elif bag_pool:
        result.pendencies.append(
            "Imagem de bag/estojo encontrada, porem sem confirmacao de que acompanha o "
            "produto; nao utilizada para evitar induzir o cliente a erro."
        )
    else:
        result.pendencies.append("Nenhuma imagem de bag/estojo confirmada disponivel para a Foto 5.")

    result.ordered_images = [foto1, foto2, foto3, foto4, foto5]

    slot_names = ["Foto1 (capa)", "Foto2 (verso/angulo)", "Foto3 (detalhe)", "Foto4 (complementar)", "Foto5 (bag)"]
    for name, image in zip(slot_names, result.ordered_images):
        if image is None and name != "Foto5 (bag)":
            result.pendencies.append(f"{name} nao encontrada com confianca suficiente.")

    return result
