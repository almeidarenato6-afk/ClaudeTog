"""Wrapper fino sobre a Google Sheets API v4 (somente leitura)."""
from __future__ import annotations

from typing import List

from googleapiclient.discovery import build


class SheetsClient:
    def __init__(self, credentials):
        self._service = build("sheets", "v4", credentials=credentials, cache_discovery=False)

    def read_range(self, spreadsheet_id: str, range_name: str) -> List[list]:
        result = (
            self._service.spreadsheets()
            .values()
            .get(spreadsheetId=spreadsheet_id, range=range_name)
            .execute()
        )
        return result.get("values", [])
