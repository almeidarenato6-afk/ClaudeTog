"""Wrapper fino sobre a Google Drive API v3, usando IDs (nunca caminhos de
texto) como referencia primaria a pastas/arquivos, com suporte a Shared
Drives (`supportsAllDrives`)."""
from __future__ import annotations

import io
from typing import List, Optional, Tuple

from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload, MediaIoBaseUpload

FOLDER_MIME_TYPE = "application/vnd.google-apps.folder"


class DriveClient:
    def __init__(self, credentials):
        self._service = build("drive", "v3", credentials=credentials, cache_discovery=False)

    def find_folder_by_name(self, parent_id: str, name: str) -> Optional[dict]:
        safe_name = name.replace("\\", "\\\\").replace("'", "\\'")
        query = (
            f"'{parent_id}' in parents and name = '{safe_name}' "
            f"and mimeType = '{FOLDER_MIME_TYPE}' and trashed = false"
        )
        response = (
            self._service.files()
            .list(
                q=query,
                fields="files(id, name)",
                spaces="drive",
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            )
            .execute()
        )
        files = response.get("files", [])
        return files[0] if files else None

    def create_folder(self, parent_id: str, name: str) -> dict:
        metadata = {"name": name, "mimeType": FOLDER_MIME_TYPE, "parents": [parent_id]}
        return (
            self._service.files()
            .create(body=metadata, fields="id, name", supportsAllDrives=True)
            .execute()
        )

    def find_or_create_folder(self, parent_id: str, name: str) -> Tuple[dict, bool]:
        existing = self.find_folder_by_name(parent_id, name)
        if existing:
            return existing, False
        return self.create_folder(parent_id, name), True

    def list_files_in_folder(self, folder_id: str) -> List[dict]:
        files: List[dict] = []
        page_token = None
        query = f"'{folder_id}' in parents and trashed = false"
        while True:
            response = (
                self._service.files()
                .list(
                    q=query,
                    fields="nextPageToken, files(id, name, mimeType, size)",
                    spaces="drive",
                    supportsAllDrives=True,
                    includeItemsFromAllDrives=True,
                    pageToken=page_token,
                )
                .execute()
            )
            files.extend(response.get("files", []))
            page_token = response.get("nextPageToken")
            if not page_token:
                break
        return files

    def upload_file(self, folder_id: str, filename: str, data: bytes, mime_type: str) -> dict:
        media = MediaIoBaseUpload(io.BytesIO(data), mimetype=mime_type, resumable=False)
        metadata = {"name": filename, "parents": [folder_id]}
        return (
            self._service.files()
            .create(body=metadata, media_body=media, fields="id, name", supportsAllDrives=True)
            .execute()
        )

    def download_file(self, file_id: str) -> bytes:
        request = self._service.files().get_media(fileId=file_id)
        buffer = io.BytesIO()
        downloader = MediaIoBaseDownload(buffer, request)
        done = False
        while not done:
            _, done = downloader.next_chunk()
        return buffer.getvalue()
