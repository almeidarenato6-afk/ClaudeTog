"""Hash exato (SHA-256) e hash perceptual (average hash) para deduplicacao.

Nao usamos a biblioteca `imagehash` para evitar a dependencia transitiva de
numpy/scipy no container; o average hash e simples o suficiente para
implementar em Pillow puro.
"""
from __future__ import annotations

import hashlib
from io import BytesIO
from typing import Iterable, List, Optional, Tuple

from PIL import Image


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def average_hash(data: bytes, hash_size: int = 8) -> str:
    with Image.open(BytesIO(data)) as img:
        gray = img.convert("L").resize((hash_size, hash_size), Image.LANCZOS)
        pixels = list(gray.getdata())
    avg = sum(pixels) / len(pixels)
    bits = "".join("1" if p >= avg else "0" for p in pixels)
    nibble_count = (hash_size * hash_size + 3) // 4
    return f"{int(bits, 2):0{nibble_count}x}"


def hamming_distance(hash_a: str, hash_b: str) -> int:
    return bin(int(hash_a, 16) ^ int(hash_b, 16)).count("1")


def is_perceptual_duplicate(hash_a: str, hash_b: str, threshold: int = 6) -> bool:
    return hamming_distance(hash_a, hash_b) <= threshold


class Deduplicator:
    """Mantem o conjunto de hashes ja vistos (existentes + processados nesta
    execucao) e decide se um novo par (sha256, phash) e uma duplicata exata
    ou visual."""

    def __init__(self, phash_threshold: int = 6):
        self.phash_threshold = phash_threshold
        self._seen_sha256: set = set()
        self._seen_phash: List[str] = []

    def seed(
        self,
        sha256_list: Optional[Iterable[str]] = None,
        phash_list: Optional[Iterable[str]] = None,
    ) -> None:
        if sha256_list:
            self._seen_sha256.update(sha256_list)
        if phash_list:
            self._seen_phash.extend(phash_list)

    def is_duplicate(self, sha256_hash: str, phash: str) -> Tuple[bool, Optional[str]]:
        if sha256_hash in self._seen_sha256:
            return True, "sha256"
        for existing in self._seen_phash:
            if is_perceptual_duplicate(existing, phash, self.phash_threshold):
                return True, "phash"
        return False, None

    def register(self, sha256_hash: str, phash: str) -> None:
        self._seen_sha256.add(sha256_hash)
        self._seen_phash.append(phash)
