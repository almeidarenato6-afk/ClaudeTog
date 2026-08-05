"""Estado persistido localmente entre execucoes (cache de idempotencia).

Guarda, por produto, o status da ultima execucao, o ID da pasta no Drive e um
cache de hashes (sha256/phash) de arquivos ja existentes no Drive, para nao
precisar rebaixar e reprocessar imagens ja catalogadas a cada execucao.

A escrita e atomica (arquivo temporario + os.replace) para que uma falha no
meio da gravacao nunca deixe o cache corrompido.
"""
from __future__ import annotations

import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Optional

STATE_VERSION = 1


def _default_state() -> Dict[str, Any]:
    return {
        "version": STATE_VERSION,
        "updated_at": None,
        "products": {},
        "folders": {},
        "file_hash_cache": {},
    }


def load_state(path: str) -> Dict[str, Any]:
    p = Path(path)
    if not p.exists():
        return _default_state()
    with p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    data.setdefault("version", STATE_VERSION)
    data.setdefault("products", {})
    data.setdefault("folders", {})
    data.setdefault("file_hash_cache", {})
    return data


def save_state(path: str, state: Dict[str, Any]) -> None:
    state["updated_at"] = datetime.now(timezone.utc).isoformat()
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_path = tempfile.mkstemp(dir=str(p.parent), suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(state, f, ensure_ascii=False, indent=2, sort_keys=True)
        os.replace(tmp_path, p)
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)


def product_key(official_name: str) -> str:
    return official_name.strip().lower()


def get_product_state(state: Dict[str, Any], official_name: str) -> Optional[Dict[str, Any]]:
    return state.get("products", {}).get(product_key(official_name))


def upsert_product_state(state: Dict[str, Any], official_name: str, **fields: Any) -> Dict[str, Any]:
    key = product_key(official_name)
    entry = state.setdefault("products", {}).setdefault(
        key, {"official_name": official_name, "images": []}
    )
    entry.update(fields)
    return entry
