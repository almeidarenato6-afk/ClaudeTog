"""Geracao do relatorio final de execucao em JSON, CSV e Markdown."""
from __future__ import annotations

import csv
import json
import logging
from dataclasses import asdict
from pathlib import Path
from typing import Dict, Optional

from .models import ExecutionReport

logger = logging.getLogger(__name__)

_MIME_BY_SUFFIX = {".json": "application/json", ".csv": "text/csv", ".md": "text/markdown"}


def write_reports(report: ExecutionReport, output_dir: str) -> Dict[str, str]:
    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    base = f"execution_{report.execution_id}"
    data = asdict(report)

    json_path = out_dir / f"{base}.json"
    json_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")

    csv_path = out_dir / f"{base}.csv"
    with csv_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["official_name", "status", "folder_id", "folder_created", "images_saved", "pendencies", "errors"]
        )
        for product in data["products"]:
            writer.writerow(
                [
                    product["official_name"],
                    product["status"],
                    product.get("folder_id") or "",
                    product.get("folder_created"),
                    "; ".join(product.get("images_saved", [])),
                    "; ".join(product.get("pendencies", [])),
                    "; ".join(product.get("errors", [])),
                ]
            )

    md_path = out_dir / f"{base}.md"
    lines = [
        f"# Relatorio de execucao {report.execution_id}",
        "",
        f"- Inicio: {report.started_at}",
        f"- Fim: {report.finished_at}",
        f"- Modo: {'DRY-RUN' if report.dry_run else 'REAL'}",
        f"- Total de produtos processados: {len(data['products'])}",
        "",
        "| Produto | Status | Imagens salvas | Pendencias | Erros |",
        "|---|---|---|---|---|",
    ]
    for product in data["products"]:
        lines.append(
            f"| {product['official_name']} | {product['status']} | "
            f"{len(product.get('images_saved', []))} | {len(product.get('pendencies', []))} | "
            f"{len(product.get('errors', []))} |"
        )

    if data.get("errors"):
        lines += ["", "## Erros gerais da execucao", ""]
        lines += [f"- {err}" for err in data["errors"]]

    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    return {"json": str(json_path), "csv": str(csv_path), "md": str(md_path)}


def upload_reports_to_drive(drive_client, reports_folder_id: str, report_paths: Dict[str, str]) -> Dict[str, Optional[str]]:
    """Envia copia dos relatorios (JSON/CSV/MD) para a subpasta configurada
    no Drive (`AGENT_REPORTS_FOLDER_ID`). Falhas de upload sao logadas mas
    nunca derrubam a execucao - os relatorios ja estao salvos localmente."""
    uploaded_ids: Dict[str, Optional[str]] = {}
    for kind, local_path in report_paths.items():
        path = Path(local_path)
        mime_type = _MIME_BY_SUFFIX.get(path.suffix, "application/octet-stream")
        try:
            data = path.read_bytes()
            uploaded = drive_client.upload_file(reports_folder_id, path.name, data, mime_type)
            uploaded_ids[kind] = uploaded.get("id")
        except Exception as exc:
            logger.warning("falha_ao_enviar_relatorio", extra={"arquivo": str(path), "erro": str(exc)})
            uploaded_ids[kind] = None
    return uploaded_ids
