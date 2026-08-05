"""Configuracao do agente, lida a partir de variaveis de ambiente.

Ver `.env.example` para a lista completa e valores padrao documentados.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Optional


def _bool_env(name: str, default: bool) -> bool:
    val = os.environ.get(name)
    if val is None or val == "":
        return default
    return val.strip().lower() in ("1", "true", "yes", "sim")


def _float_env(name: str, default: float) -> float:
    val = os.environ.get(name)
    return float(val) if val else default


def _int_env(name: str, default: int) -> int:
    val = os.environ.get(name)
    return int(val) if val else default


@dataclass
class Config:
    google_credentials_json: Optional[str] = field(
        default_factory=lambda: os.environ.get("GOOGLE_CREDENTIALS_JSON") or None
    )
    google_application_credentials: Optional[str] = field(
        default_factory=lambda: os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or None
    )
    drive_root_folder_id: Optional[str] = field(
        default_factory=lambda: os.environ.get("GOOGLE_DRIVE_ROOT_FOLDER_ID") or None
    )
    fotos_ecommerce_folder_id: Optional[str] = field(
        default_factory=lambda: os.environ.get("FOTOS_ECOMMERCE_FOLDER_ID") or None
    )
    fotos_ecommerce_folder_name: str = field(
        default_factory=lambda: os.environ.get("FOTOS_ECOMMERCE_FOLDER_NAME", "Fotos E-commerce")
    )
    agent_reports_folder_id: Optional[str] = field(
        default_factory=lambda: os.environ.get("AGENT_REPORTS_FOLDER_ID") or None
    )
    catalog_spreadsheet_id: Optional[str] = field(
        default_factory=lambda: os.environ.get("CATALOG_SPREADSHEET_ID") or None
    )
    catalog_range: str = field(
        default_factory=lambda: os.environ.get("CATALOG_RANGE", "Catalogo!A2:F")
    )
    timezone: str = field(default_factory=lambda: os.environ.get("TIMEZONE", "America/Sao_Paulo"))

    min_image_side: int = field(default_factory=lambda: _int_env("MIN_IMAGE_SIDE", 1000))
    preferred_image_side: int = field(default_factory=lambda: _int_env("PREFERRED_IMAGE_SIDE", 1500))
    max_images_per_product: int = field(default_factory=lambda: _int_env("MAX_IMAGES_PER_PRODUCT", 5))

    match_confidence_threshold: float = field(
        default_factory=lambda: _float_env("MATCH_CONFIDENCE_THRESHOLD", 0.72)
    )
    phash_distance_threshold: int = field(
        default_factory=lambda: _int_env("PHASH_DISTANCE_THRESHOLD", 6)
    )

    http_min_interval_seconds: float = field(
        default_factory=lambda: _float_env("HTTP_MIN_INTERVAL_SECONDS", 2.0)
    )
    http_timeout_seconds: float = field(default_factory=lambda: _float_env("HTTP_TIMEOUT_SECONDS", 15.0))
    http_max_retries: int = field(default_factory=lambda: _int_env("HTTP_MAX_RETRIES", 3))
    circuit_failure_threshold: int = field(
        default_factory=lambda: _int_env("CIRCUIT_FAILURE_THRESHOLD", 5)
    )
    circuit_cooldown_seconds: float = field(
        default_factory=lambda: _float_env("CIRCUIT_COOLDOWN_SECONDS", 300.0)
    )

    state_file_path: str = field(default_factory=lambda: os.environ.get("STATE_FILE_PATH", "data/state.json"))
    reports_dir: str = field(default_factory=lambda: os.environ.get("REPORTS_DIR", "data/relatorios"))

    dry_run: bool = field(default_factory=lambda: _bool_env("DRY_RUN", True))
    log_level: str = field(default_factory=lambda: os.environ.get("LOG_LEVEL", "INFO"))

    @classmethod
    def from_env(cls) -> "Config":
        return cls()
