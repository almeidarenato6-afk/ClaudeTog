"""Extracao de imagens de produto a partir de HTML, preferindo dados
estruturados (JSON-LD Product, Open Graph) e caindo para tags <img> com
heuristicas de papel (capa/verso/detalhe/bag) baseadas em texto proximo.
"""
from __future__ import annotations

import json
import re
from typing import List
from urllib.parse import urljoin

from bs4 import BeautifulSoup

from ..models import ImageCandidate

_ANGLE_KEYWORDS = {
    "bag": ["bag", "capa protetora", "case", "estojo", "bolsa", "mochila"],
    "verso": ["verso", "costas", "traseir", "back", "reverso"],
    "detalhe": ["detalhe", "zoom", "textura", "face", "superficie", "aproxima"],
    "inclinado": ["inclinad", "3/4", "perspectiv", "angulo"],
    "frontal": ["frente", "frontal", "capa"],
}

_INCLUSION_HINTS = ("inclu", "acompanha", "junto com", "vem com")


def guess_role_and_angle(text: str):
    lowered = (text or "").lower()
    if any(k in lowered for k in _ANGLE_KEYWORDS["bag"]):
        return "bag", None
    if any(k in lowered for k in _ANGLE_KEYWORDS["verso"]):
        return "verso", "verso"
    if any(k in lowered for k in _ANGLE_KEYWORDS["detalhe"]):
        return "detalhe", None
    if any(k in lowered for k in _ANGLE_KEYWORDS["inclinado"]):
        return "capa", "inclinado"
    if any(k in lowered for k in _ANGLE_KEYWORDS["frontal"]):
        return "capa", "frontal"
    return "other", None


def _extract_json_ld_images(soup: BeautifulSoup) -> List[dict]:
    out = []
    for tag in soup.find_all("script", attrs={"type": "application/ld+json"}):
        try:
            data = json.loads(tag.string or "{}")
        except (json.JSONDecodeError, TypeError):
            continue
        items = data if isinstance(data, list) else [data]
        for item in items:
            if not isinstance(item, dict):
                continue
            item_type = item.get("@type")
            if item_type != "Product" and "Product" not in (item_type or []):
                continue
            images = item.get("image")
            if isinstance(images, str):
                images = [images]
            for img_url in images or []:
                out.append({"url": img_url, "text": item.get("name", "")})
    return out


def _extract_open_graph_images(soup: BeautifulSoup) -> List[dict]:
    out = []
    for tag in soup.find_all("meta", attrs={"property": "og:image"}):
        content = tag.get("content")
        if content:
            out.append({"url": content, "text": ""})
    return out


def _extract_img_tags(soup: BeautifulSoup) -> List[dict]:
    out = []
    for tag in soup.find_all("img"):
        src = tag.get("src") or tag.get("data-src")
        if not src:
            continue
        out.append({"url": src, "text": tag.get("alt", "")})
    return out


def build_candidates(html: str, page_url: str, source_name: str) -> List[ImageCandidate]:
    soup = BeautifulSoup(html, "html.parser")
    raw_images = (
        _extract_json_ld_images(soup) + _extract_open_graph_images(soup) + _extract_img_tags(soup)
    )
    page_text = soup.get_text(" ", strip=True)[:5000]
    page_text_lower = page_text.lower()

    seen = set()
    candidates: List[ImageCandidate] = []
    for raw in raw_images:
        url = urljoin(page_url, raw["url"])
        if not url or url in seen:
            continue
        seen.add(url)

        role, angle = guess_role_and_angle(f"{raw.get('text', '')} {url}")
        bag_confirmed = role == "bag" and any(hint in page_text_lower for hint in _INCLUSION_HINTS)

        candidates.append(
            ImageCandidate(
                url=url,
                page_url=page_url,
                source_name=source_name,
                role_hint=role,
                angle=angle,
                alt_text=raw.get("text", ""),
                page_text=page_text,
                filename_hint=re.sub(r"[?#].*$", "", url).rsplit("/", 1)[-1],
                bag_confirmed=bag_confirmed,
            )
        )
    return candidates
