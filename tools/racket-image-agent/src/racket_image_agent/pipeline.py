"""Orquestrador do agente: le o catalogo, decide o que processar de forma
incremental/idempotente, busca e valida imagens, seleciona as 5 fotos finais
e (fora do dry-run) grava no Drive. Erros por produto nunca interrompem o
lote inteiro.
"""
from __future__ import annotations

import logging
import re
import uuid
from datetime import datetime, timezone
from typing import List, Optional

from .config import Config
from .imaging.hashing import Deduplicator, average_hash, sha256_bytes
from .imaging.selection import select_five_photos
from .imaging.validation import validate_image
from .matching import compute_confidence, meets_threshold
from .models import ExecutionReport, ImageCandidate, Product, ProductReportEntry, ProductStatus
from .name_normalizer import build_image_filename, build_official_name
from .sourcing.http_client import USER_AGENT
from .sourcing.pipeline_search import search_all_sources
from .sourcing.robots import is_allowed
from .state_store import load_state, save_state, upsert_product_state

logger = logging.getLogger(__name__)

FILENAME_RE = re.compile(r"^(?P<num>[1-5]) - (?P<name>.+)\.(?P<ext>jpe?g|png)$", re.IGNORECASE)

_MIME_BY_EXT = {"jpg": "image/jpeg", "png": "image/png"}


def is_expected_filename(filename: str, official_name: str) -> bool:
    match = FILENAME_RE.match(filename)
    if not match:
        return False
    return match.group("name").strip().lower() == official_name.strip().lower()


def missing_slots(existing_files: List[dict], official_name: str) -> List[int]:
    present = set()
    for f in existing_files:
        match = FILENAME_RE.match(f["name"])
        if match and match.group("name").strip().lower() == official_name.strip().lower():
            present.add(int(match.group("num")))
    return [n for n in range(1, 6) if n not in present]


class Pipeline:
    def __init__(
        self,
        config: Config,
        drive_client=None,
        sheets_client=None,
        http_client=None,
        catalog: Optional[List[Product]] = None,
    ):
        self.config = config
        self.drive_client = drive_client
        self.sheets_client = sheets_client
        self.http_client = http_client
        self._catalog_override = catalog
        self.state = load_state(config.state_file_path)
        self._robots_cache: dict = {}

    # -- catalogo -----------------------------------------------------------

    def load_catalog(self) -> List[Product]:
        if self._catalog_override is not None:
            return self._catalog_override
        if not self.sheets_client or not self.config.catalog_spreadsheet_id:
            raise RuntimeError(
                "SheetsClient e/ou CATALOG_SPREADSHEET_ID nao configurados; "
                "nao ha catalogo de raquetes para processar."
            )
        rows = self.sheets_client.read_range(self.config.catalog_spreadsheet_id, self.config.catalog_range)
        products: List[Product] = []
        for i, row in enumerate(rows, start=2):
            padded = list(row) + [""] * (6 - len(row))
            brand, model, year, color, version, _extra = padded[:6]
            if not brand or not model:
                continue
            products.append(
                Product(
                    brand=brand.strip(),
                    model=model.strip(),
                    year=(year or "").strip() or None,
                    color=(color or "").strip() or None,
                    version=(version or "").strip() or None,
                    source_row=i,
                    source_sheet_id=self.config.catalog_spreadsheet_id,
                )
            )
        return products

    # -- Drive: pasta raiz "Fotos E-commerce" --------------------------------

    def resolve_fotos_ecommerce_folder_id(self) -> str:
        if self.config.fotos_ecommerce_folder_id:
            return self.config.fotos_ecommerce_folder_id

        cached = self.state.get("folders", {}).get("fotos_ecommerce_id")
        if cached:
            return cached

        if not self.drive_client or not self.config.drive_root_folder_id:
            raise RuntimeError(
                "Nao foi possivel localizar a pasta 'Fotos E-commerce': defina "
                "FOTOS_ECOMMERCE_FOLDER_ID ou GOOGLE_DRIVE_ROOT_FOLDER_ID."
            )
        folder = self.drive_client.find_folder_by_name(
            self.config.drive_root_folder_id, self.config.fotos_ecommerce_folder_name
        )
        if not folder:
            raise RuntimeError(
                f"Pasta '{self.config.fotos_ecommerce_folder_name}' nao encontrada dentro "
                "da estrutura oficial do Drive (GOOGLE_DRIVE_ROOT_FOLDER_ID)."
            )
        self.state.setdefault("folders", {})["fotos_ecommerce_id"] = folder["id"]
        return folder["id"]

    # -- execucao -------------------------------------------------------------

    def run(self) -> ExecutionReport:
        execution_id = str(uuid.uuid4())
        started_at = datetime.now(timezone.utc).isoformat()
        report = ExecutionReport(execution_id=execution_id, started_at=started_at, dry_run=self.config.dry_run)

        if self.config.catalog_spreadsheet_id:
            report.sheet_sources.append(
                {"spreadsheet_id": self.config.catalog_spreadsheet_id, "range": self.config.catalog_range}
            )

        try:
            products = self.load_catalog()
        except Exception as exc:
            logger.error("erro_catalogo", extra={"erro": str(exc)})
            report.errors.append(f"Falha ao ler catalogo: {exc}")
            report.finished_at = datetime.now(timezone.utc).isoformat()
            return report

        try:
            fotos_root_id = self.resolve_fotos_ecommerce_folder_id()
        except Exception as exc:
            logger.error("erro_pasta_raiz", extra={"erro": str(exc)})
            report.errors.append(str(exc))
            report.finished_at = datetime.now(timezone.utc).isoformat()
            return report

        for product in products:
            entry = self._process_product(product, fotos_root_id, execution_id)
            report.products.append(entry)

        if not self.config.dry_run:
            save_state(self.config.state_file_path, self.state)

        report.finished_at = datetime.now(timezone.utc).isoformat()
        return report

    # -- por produto ------------------------------------------------------------

    def _process_product(self, product: Product, fotos_root_id: str, execution_id: str) -> ProductReportEntry:
        official_name = build_official_name(product.brand, product.model, product.year, product.color, product.version)
        entry = ProductReportEntry(official_name=official_name, status=ProductStatus.NAO_ENCONTRADO.value)

        try:
            folder = None
            if self.drive_client:
                folder = self.drive_client.find_folder_by_name(fotos_root_id, official_name)
            entry.folder_id = folder["id"] if folder else None

            existing_files = self.drive_client.list_files_in_folder(folder["id"]) if folder else []
            valid_existing = [f for f in existing_files if is_expected_filename(f["name"], official_name)]

            if len(valid_existing) >= self.config.max_images_per_product:
                entry.status = ProductStatus.IGNORADO.value
                upsert_product_state(
                    self.state, official_name,
                    status=entry.status, folder_id=entry.folder_id, last_execution_id=execution_id,
                )
                return entry

            slots_to_fill = missing_slots(valid_existing, official_name)

            dedup = Deduplicator(phash_threshold=self.config.phash_distance_threshold)
            existing_hashes = self._hash_existing_files(valid_existing)
            dedup.seed(
                sha256_list=[h["sha256"] for h in existing_hashes],
                phash_list=[h["phash"] for h in existing_hashes],
            )

            candidates = search_all_sources(product, self.http_client, self.config, self._robots_cache, logger)
            entry.source_urls = sorted({c.page_url for c in candidates})

            scored_pool, had_low_confidence = self._download_validate_score(product, candidates, dedup, entry)

            selection = select_five_photos(scored_pool)
            entry.pendencies.extend(selection.pendencies)

            newly_saved = self._save_selected_images(
                official_name, selection.ordered_images, slots_to_fill, folder, fotos_root_id, entry
            )

            entry.status = self._decide_status(
                existing_count=len(valid_existing),
                newly_saved=newly_saved,
                had_low_confidence=had_low_confidence,
                found_any_candidate=bool(candidates),
            )

            upsert_product_state(
                self.state, official_name,
                status=entry.status, folder_id=entry.folder_id, last_execution_id=execution_id,
            )
        except Exception as exc:
            logger.error("erro_produto", extra={"produto": official_name, "erro": str(exc)})
            entry.status = ProductStatus.NAO_ENCONTRADO.value
            entry.errors.append(str(exc))

        return entry

    def _decide_status(
        self, existing_count: int, newly_saved: int, had_low_confidence: bool, found_any_candidate: bool
    ) -> str:
        total_after = existing_count + newly_saved
        if total_after >= self.config.max_images_per_product:
            return ProductStatus.CONCLUIDO.value
        if newly_saved > 0 or existing_count > 0:
            return ProductStatus.PARCIAL.value
        if had_low_confidence:
            return ProductStatus.REVISAO.value
        if not found_any_candidate:
            return ProductStatus.NAO_ENCONTRADO.value
        return ProductStatus.REVISAO.value

    def _hash_existing_files(self, files: List[dict]) -> List[dict]:
        hashes = []
        cache = self.state.setdefault("file_hash_cache", {})
        for f in files:
            file_id = f["id"]
            cached = cache.get(file_id)
            if cached:
                hashes.append(cached)
                continue
            if not self.drive_client:
                continue
            try:
                data = self.drive_client.download_file(file_id)
            except Exception as exc:
                logger.warning("erro_hash_existente", extra={"file_id": file_id, "erro": str(exc)})
                continue
            record = {"sha256": sha256_bytes(data), "phash": average_hash(data), "file_id": file_id}
            cache[file_id] = record
            hashes.append(record)
        return hashes

    def _download_validate_score(self, product, candidates, dedup, entry):
        scored_pool: List[ImageCandidate] = []
        had_low_confidence = False

        for candidate in candidates:
            if not is_allowed(candidate.url, USER_AGENT, self._robots_cache):
                entry.pendencies.append(f"Bloqueada por robots.txt: {candidate.url}")
                continue

            try:
                response = self.http_client.get(candidate.url)
                data = response.content
            except Exception as exc:
                entry.errors.append(f"Falha ao baixar {candidate.url}: {exc}")
                continue

            validation = validate_image(data, self.config.min_image_side, self.config.preferred_image_side)
            if not validation.ok:
                entry.pendencies.append(f"Rejeitada ({validation.reason}): {candidate.url}")
                continue
            if validation.pending_low_resolution:
                entry.pendencies.append(
                    f"Resolucao abaixo do ideal ({validation.width}x{validation.height}): {candidate.url}"
                )

            sha = sha256_bytes(data)
            phash = average_hash(data)
            is_dup, dup_kind = dedup.is_duplicate(sha, phash)
            if is_dup:
                entry.pendencies.append(f"Duplicata ({dup_kind}) ignorada: {candidate.url}")
                continue

            score = compute_confidence(product, candidate)
            if not meets_threshold(score, self.config.match_confidence_threshold):
                had_low_confidence = True
                entry.pendencies.append(f"REVISAO: confianca {score} abaixo do limiar para {candidate.url}")
                continue

            candidate.width, candidate.height, candidate.format = validation.width, validation.height, validation.format
            candidate.sha256, candidate.phash, candidate.confidence = sha, phash, score
            candidate.data = data
            dedup.register(sha, phash)
            scored_pool.append(candidate)

        return scored_pool, had_low_confidence

    def _save_selected_images(self, official_name, ordered_images, slots_to_fill, folder, fotos_root_id, entry) -> int:
        newly_saved = 0
        slots_to_fill_set = set(slots_to_fill)

        for slot_number, candidate in zip(range(1, 6), ordered_images):
            if candidate is None or slot_number not in slots_to_fill_set:
                continue

            ext = "png" if candidate.format == "PNG" else "jpg"
            filename = build_image_filename(slot_number, official_name, ext)

            if self.config.dry_run:
                entry.images_saved.append(f"(dry-run) {filename}")
            else:
                if folder is None:
                    folder = self.drive_client.create_folder(fotos_root_id, official_name)
                    entry.folder_id = folder["id"]
                    entry.folder_created = True
                uploaded = self.drive_client.upload_file(
                    folder["id"], filename, candidate.data, _MIME_BY_EXT[ext]
                )
                entry.images_saved.append(filename)
                self.state.setdefault("file_hash_cache", {})[uploaded["id"]] = {
                    "sha256": candidate.sha256, "phash": candidate.phash, "file_id": uploaded["id"],
                }

            entry.resolutions[filename] = f"{candidate.width}x{candidate.height}"
            entry.hashes[filename] = {"sha256": candidate.sha256, "phash": candidate.phash}
            newly_saved += 1

        return newly_saved
