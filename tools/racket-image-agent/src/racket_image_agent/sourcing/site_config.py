"""Carrega overrides de configuracao das fontes (templates de busca por site
e dominios oficiais de fabricante) a partir de arquivos JSON versionados em
`config/`, para que a homologacao possa confirmar/ajustar URLs reais sem
alterar codigo.
"""
from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Dict, Optional

logger = logging.getLogger(__name__)

_PROJECT_ROOT = Path(__file__).resolve().parents[3]
SOURCES_CONFIG_PATH = _PROJECT_ROOT / "config" / "sources.json"
MANUFACTURER_DOMAINS_PATH = _PROJECT_ROOT / "config" / "manufacturer_domains.json"


def _load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        logger.warning("falha_ao_ler_config", extra={"arquivo": str(path), "erro": str(exc)})
        return {}


def load_sources_config(path: Optional[Path] = None) -> Dict[str, dict]:
    return _load_json(path or SOURCES_CONFIG_PATH)


def load_manufacturer_domains(path: Optional[Path] = None) -> Dict[str, Optional[str]]:
    return _load_json(path or MANUFACTURER_DOMAINS_PATH)
