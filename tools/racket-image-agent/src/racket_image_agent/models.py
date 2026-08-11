from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import List, Optional


class ProductStatus(str, Enum):
    CONCLUIDO = "CONCLUIDO"
    PARCIAL = "PARCIAL"
    REVISAO = "REVISAO"
    NAO_ENCONTRADO = "NAO_ENCONTRADO"
    IGNORADO = "IGNORADO"


@dataclass
class Product:
    brand: str
    model: str
    year: Optional[str] = None
    color: Optional[str] = None
    version: Optional[str] = None
    source_row: Optional[int] = None
    source_sheet_id: Optional[str] = None


@dataclass
class ImageCandidate:
    """Uma imagem candidata encontrada em uma das fontes, ainda nao validada."""

    url: str
    page_url: str
    source_name: str
    role_hint: str = "other"  # capa|verso|detalhe|complementar|bag|other
    angle: Optional[str] = None  # "inclinado"|"frontal"|...
    bag_confirmed: bool = False
    alt_text: str = ""
    page_text: str = ""
    filename_hint: str = ""

    # Preenchido apos download/validacao:
    data: Optional[bytes] = field(default=None, repr=False)
    width: Optional[int] = None
    height: Optional[int] = None
    format: Optional[str] = None
    sha256: Optional[str] = None
    phash: Optional[str] = None
    confidence: float = 0.0


@dataclass
class ProductReportEntry:
    official_name: str
    status: str
    folder_id: Optional[str] = None
    folder_created: bool = False
    images_saved: List[str] = field(default_factory=list)
    source_urls: List[str] = field(default_factory=list)
    pendencies: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    resolutions: dict = field(default_factory=dict)
    hashes: dict = field(default_factory=dict)


@dataclass
class ExecutionReport:
    execution_id: str
    started_at: str
    finished_at: Optional[str] = None
    dry_run: bool = True
    sheet_sources: List[dict] = field(default_factory=list)
    products: List[ProductReportEntry] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
