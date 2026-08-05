"""Ponto de entrada de linha de comando.

Uso:
    racket-image-agent --dry-run
    racket-image-agent --real-run
"""
from __future__ import annotations

import argparse
import logging
import sys

from .config import Config
from .google.auth import load_credentials
from .google.drive_client import DriveClient
from .google.sheets_client import SheetsClient
from .logging_setup import configure_logging
from .pipeline import Pipeline
from .reporting import upload_reports_to_drive, write_reports
from .sourcing.http_client import RateLimitedClient

logger = logging.getLogger("racket_image_agent")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="racket-image-agent")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Forca modo dry-run (sobrepoe DRY_RUN do ambiente).")
    mode.add_argument("--real-run", action="store_true", help="Forca execucao real (sobrepoe DRY_RUN do ambiente).")
    parser.add_argument("--reports-dir", default=None, help="Sobrepoe REPORTS_DIR.")
    return parser


def main(argv=None) -> int:
    args = build_parser().parse_args(argv)

    config = Config.from_env()
    if args.dry_run:
        config.dry_run = True
    if args.real_run:
        config.dry_run = False
    if args.reports_dir:
        config.reports_dir = args.reports_dir

    configure_logging(config.log_level)
    logger.info("iniciando_execucao", extra={"dry_run": config.dry_run})

    credentials = load_credentials()
    drive_client = DriveClient(credentials)
    sheets_client = SheetsClient(credentials)
    http_client = RateLimitedClient(
        min_interval_seconds=config.http_min_interval_seconds,
        timeout_seconds=config.http_timeout_seconds,
        max_retries=config.http_max_retries,
        failure_threshold=config.circuit_failure_threshold,
        circuit_cooldown_seconds=config.circuit_cooldown_seconds,
    )

    pipeline = Pipeline(config, drive_client=drive_client, sheets_client=sheets_client, http_client=http_client)
    report = pipeline.run()
    paths = write_reports(report, config.reports_dir)

    if not config.dry_run and config.agent_reports_folder_id:
        uploaded = upload_reports_to_drive(drive_client, config.agent_reports_folder_id, paths)
        logger.info("relatorios_enviados_ao_drive", extra={"arquivos": uploaded})

    logger.info(
        "execucao_concluida",
        extra={
            "execution_id": report.execution_id,
            "dry_run": report.dry_run,
            "produtos": len(report.products),
            "erros_gerais": len(report.errors),
            "relatorios": paths,
        },
    )
    print(f"Execucao {report.execution_id} concluida. Relatorios em: {paths}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
