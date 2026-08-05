"""Geradores de imagens sinteticas usados nos testes (sem depender de
arquivos de fixture binarios versionados)."""
from __future__ import annotations

import random
from io import BytesIO

from PIL import Image, ImageDraw

_GRID = 8


def _draw_seeded_grid(img: Image.Image, color) -> None:
    """Preenche a imagem com um grid 8x8 de blocos claro/escuro, cujo padrao
    espacial e determinado (e reproduzivel) pela tupla `color`. Isso produz
    imagens "diferentes" com average-hash de fato diferente (ao contrario de
    uma cor solida, cujo hash e sempre igual independente da cor), enquanto
    permanece estavel sob redimensionamento (o grid se alinha com o
    hash_size=8 usado em average_hash)."""
    width, height = img.size
    draw = ImageDraw.Draw(img)
    cell_w, cell_h = width // _GRID, height // _GRID
    rng = random.Random(str(color))
    dark = tuple(max(0, c - 90) for c in color)
    light = tuple(min(255, c + 90) for c in color)
    for i in range(_GRID):
        for j in range(_GRID):
            shade = light if rng.random() >= 0.5 else dark
            x0, y0 = i * cell_w, j * cell_h
            x1 = width if i == _GRID - 1 else (i + 1) * cell_w
            y1 = height if j == _GRID - 1 else (j + 1) * cell_h
            draw.rectangle([x0, y0, x1, y1], fill=shade)


def make_jpeg(width: int = 1600, height: int = 1600, color=(190, 190, 190)) -> bytes:
    img = Image.new("RGB", (width, height), color)
    _draw_seeded_grid(img, color)
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()


def make_png(width: int = 1600, height: int = 1600, color=(190, 190, 190)) -> bytes:
    img = Image.new("RGB", (width, height), color)
    _draw_seeded_grid(img, color)
    buf = BytesIO()
    img.save(buf, format="PNG")
    return buf.getvalue()


def make_flat_jpeg(width: int = 1600, height: int = 1600, color=(190, 190, 190)) -> bytes:
    """Imagem de cor solida (sem grid), usada quando o teste so precisa de
    um arquivo JPEG valido com determinada resolucao, sem se importar com o
    conteudo (ex.: testes de validacao de resolucao/tipo de arquivo)."""
    img = Image.new("RGB", (width, height), color)
    buf = BytesIO()
    img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()


def make_watermarked_jpeg(width: int = 1600, height: int = 1600, color=(190, 190, 190)) -> bytes:
    """Imagem uniforme com um bloco de alto contraste (padrao xadrez denso)
    no canto inferior direito, simulando uma marca d'agua/selo."""
    img = Image.new("RGB", (width, height), color)
    draw = ImageDraw.Draw(img)

    corner_w, corner_h = int(width * 0.18), int(height * 0.18)
    x0, y0 = width - corner_w, height - corner_h
    step = 4
    for x in range(x0, width, step):
        for y in range(y0, height, step):
            if ((x // step) + (y // step)) % 2 == 0:
                draw.rectangle([x, y, x + step - 1, y + step - 1], fill=(10, 10, 10))

    buf = BytesIO()
    img.save(buf, format="JPEG", quality=90)
    return buf.getvalue()


def make_not_an_image() -> bytes:
    return b"isto claramente nao e uma imagem valida, apenas texto puro"
