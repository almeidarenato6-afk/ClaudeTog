"""Normalizacao do nome oficial da raquete e nomenclatura das imagens.

O "nome oficial" e formado por marca + modelo (+ versao, cor, ano quando
existirem) a partir dos dados vindos da fonte mais confiavel disponivel para
aquele produto (planilha de catalogo curada manualmente > pagina oficial do
fabricante > demais fontes), na ordem definida pelo chamador. Este modulo
apenas normaliza o texto ja escolhido; a escolha da fonte mais confiavel e
responsabilidade do pipeline/matching.
"""
from __future__ import annotations

import re
from typing import Optional

_KNOWN_BRANDS = {
    "nox": "NOX",
    "heroes": "Heroe's",
    "heroe's": "Heroe's",
    "drop shot": "Drop Shot",
    "dropshot": "Drop Shot",
    "ama": "AMA",
    "adidas": "Adidas",
    "bullpadel": "Bullpadel",
    "head": "Head",
    "wilson": "Wilson",
    "babolat": "Babolat",
    "shark": "Shark",
    "mormaii": "Mormaii",
    "quicksand": "Quicksand",
    "black crown": "Black Crown",
    "lok": "LOK",
    "vision": "Vision",
    "joma": "Joma",
    "kona": "Kona",
    "totalfun": "TotalFun",
    "sexy brand": "Sexy Brand",
}

_ILLEGAL_DRIVE_CHARS_RE = re.compile(r'[\\/:*?"<>|]')
_MULTI_SPACE_RE = re.compile(r"\s+")

FORBIDDEN_FILENAME_SUFFIXES = (
    "final",
    "editada",
    "edicao",
    "edição",
    "copia",
    "cópia",
    "nova",
    "versao",
    "versão",
)


def normalize_brand(brand: str) -> str:
    key = _MULTI_SPACE_RE.sub(" ", brand.strip().lower())
    return _KNOWN_BRANDS.get(key, brand.strip().title())


def clean_fragment(text: str) -> str:
    text = _MULTI_SPACE_RE.sub(" ", text.strip())
    return text.strip(" -_/")


def build_official_name(
    brand: str,
    model: str,
    year: Optional[str] = None,
    color: Optional[str] = None,
    version: Optional[str] = None,
) -> str:
    """Monta o nome oficial normalizado: 'Marca Modelo [Versao] [Cor] [Ano]'."""
    parts = [normalize_brand(brand), clean_fragment(model)]
    if version:
        parts.append(clean_fragment(str(version)))
    if color:
        parts.append(clean_fragment(str(color)))
    if year:
        parts.append(clean_fragment(str(year)))

    name = " ".join(p for p in parts if p)
    name = _MULTI_SPACE_RE.sub(" ", name).strip()
    # Nomes de pasta/arquivo no Drive nao podem conter estes caracteres.
    name = _ILLEGAL_DRIVE_CHARS_RE.sub("", name)
    return name


def build_image_filename(index: int, official_name: str, ext: str) -> str:
    """Gera o nome de arquivo padrao: '<indice> - <Nome Oficial>.<ext>'."""
    if index not in (1, 2, 3, 4, 5):
        raise ValueError("indice de foto deve estar entre 1 e 5")
    ext = ext.lower().lstrip(".")
    if ext == "jpeg":
        ext = "jpg"
    if ext not in ("jpg", "png"):
        ext = "jpg"
    return f"{index} - {official_name}.{ext}"
