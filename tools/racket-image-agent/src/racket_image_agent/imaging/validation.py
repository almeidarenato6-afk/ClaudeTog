"""Validacoes tecnicas de imagem: tipo real de arquivo, resolucao e suspeita
de marca d'agua.

A deteccao de marca d'agua e um heuristico (nao ha modelo de visao
computacional embarcado neste v1.0): compara a densidade de bordas nos
quatro cantos da imagem contra a densidade de bordas do centro. Selos,
logotipos e textos sobrepostos tipicamente introduzem alta densidade de
bordas em uma regiao onde o produto fotografado (fundo neutro) nao teria.
Falsos positivos/negativos sao esperados; por isso o pipeline sempre marca
a pendencia e, quando a imagem e descartada por este motivo, ela nunca e
usada automaticamente - fica para revisao humana via relatorio.
"""
from __future__ import annotations

from dataclasses import dataclass
from io import BytesIO
from typing import Optional

from PIL import Image, ImageFilter, UnidentifiedImageError

ALLOWED_FORMATS = {"JPEG": "jpg", "PNG": "png"}


@dataclass
class ValidationResult:
    ok: bool
    width: int
    height: int
    format: Optional[str]
    reason: Optional[str] = None
    pending_low_resolution: bool = False
    pending_watermark_suspect: bool = False


def sniff_real_format(data: bytes) -> Optional[str]:
    """Verifica o tipo real do arquivo (nao confia em extensao/Content-Type)."""
    try:
        with Image.open(BytesIO(data)) as img:
            img.verify()
        with Image.open(BytesIO(data)) as img:
            return img.format
    except (UnidentifiedImageError, OSError, ValueError):
        return None


def detect_probable_watermark(
    data: bytes, corner_ratio: float = 0.18, sensitivity: float = 1.8
) -> bool:
    try:
        with Image.open(BytesIO(data)) as img:
            gray = img.convert("L")
            width, height = gray.size
            edges = gray.filter(ImageFilter.FIND_EDGES)

            corner_w = max(1, int(width * corner_ratio))
            corner_h = max(1, int(height * corner_ratio))
            corners = [
                edges.crop((0, 0, corner_w, corner_h)),
                edges.crop((width - corner_w, 0, width, corner_h)),
                edges.crop((0, height - corner_h, corner_w, height)),
                edges.crop((width - corner_w, height - corner_h, width, height)),
            ]

            def mean_intensity(im: Image.Image) -> float:
                pixels = list(im.getdata())
                return sum(pixels) / len(pixels) if pixels else 0.0

            center_box = (corner_w, corner_h, max(corner_w + 1, width - corner_w), max(corner_h + 1, height - corner_h))
            if center_box[2] > center_box[0] and center_box[3] > center_box[1]:
                center_mean = mean_intensity(edges.crop(center_box))
            else:
                center_mean = mean_intensity(edges)

            baseline = max(center_mean, 1.0)
            corner_means = [mean_intensity(c) for c in corners]
            return any(cm > baseline * sensitivity and cm > 12 for cm in corner_means)
    except (UnidentifiedImageError, OSError, ValueError):
        return False


def validate_image(
    data: bytes,
    min_side: int = 1000,
    preferred_side: int = 1500,
    check_watermark: bool = True,
) -> ValidationResult:
    fmt = sniff_real_format(data)
    if fmt not in ALLOWED_FORMATS:
        return ValidationResult(False, 0, 0, fmt, reason="tipo_arquivo_invalido")

    with Image.open(BytesIO(data)) as img:
        width, height = img.size

    max_side = max(width, height)
    if max_side < min_side:
        return ValidationResult(
            False, width, height, fmt, reason="resolucao_baixa", pending_low_resolution=True
        )

    pending_low = max_side < preferred_side

    if check_watermark and detect_probable_watermark(data):
        return ValidationResult(
            False, width, height, fmt, reason="marca_dagua_suspeita", pending_watermark_suspect=True
        )

    return ValidationResult(True, width, height, fmt, pending_low_resolution=pending_low)
