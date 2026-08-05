"""Duplos de teste (fakes) para Drive e HTTP, usados nos testes de
integracao do pipeline sem tocar em rede/Google real."""
from __future__ import annotations

from typing import Dict, List, Optional, Tuple


class SimpleResponse:
    def __init__(self, content: bytes = b"", status_code: int = 200):
        self.content = content
        self.status_code = status_code

    @property
    def text(self) -> str:
        return self.content.decode("utf-8", errors="ignore")


class FakeHttpClient:
    def __init__(self):
        self.pages: Dict[str, SimpleResponse] = {}
        self.calls: List[str] = []

    def add(self, url: str, content, status_code: int = 200) -> None:
        if isinstance(content, str):
            content = content.encode("utf-8")
        self.pages[url] = SimpleResponse(content, status_code)

    def get(self, url: str, **kwargs) -> SimpleResponse:
        self.calls.append(url)
        if url not in self.pages:
            return SimpleResponse(b"", 404)
        return self.pages[url]


class FakeDriveClient:
    """Simula Drive com IDs, sem dependencia de rede: pastas indexadas por
    (parent_id, name) e arquivos indexados por folder_id."""

    FOLDER_MIME_TYPE = "application/vnd.google-apps.folder"

    def __init__(self):
        self._folders: Dict[Tuple[str, str], dict] = {}
        self._files: Dict[str, List[dict]] = {}
        self._contents: Dict[str, bytes] = {}
        self._next_id = 0
        self.create_folder_calls: List[Tuple[str, str]] = []
        self.upload_calls: List[Tuple[str, str]] = []

    def _gen_id(self, prefix: str) -> str:
        self._next_id += 1
        return f"{prefix}{self._next_id}"

    def find_folder_by_name(self, parent_id: str, name: str) -> Optional[dict]:
        return self._folders.get((parent_id, name))

    def create_folder(self, parent_id: str, name: str) -> dict:
        self.create_folder_calls.append((parent_id, name))
        folder = {"id": self._gen_id("folder"), "name": name}
        self._folders[(parent_id, name)] = folder
        self._files.setdefault(folder["id"], [])
        return folder

    def list_files_in_folder(self, folder_id: str) -> List[dict]:
        return list(self._files.get(folder_id, []))

    def upload_file(self, folder_id: str, filename: str, data: bytes, mime_type: str) -> dict:
        self.upload_calls.append((folder_id, filename))
        file = {"id": self._gen_id("file"), "name": filename, "mimeType": mime_type}
        self._files.setdefault(folder_id, []).append(file)
        self._contents[file["id"]] = data
        return file

    def download_file(self, file_id: str) -> bytes:
        return self._contents[file_id]

    # -- helpers de teste (nao contam como chamadas feitas pelo pipeline) -----

    def seed_folder(self, parent_id: str, name: str, files_with_data) -> dict:
        folder = {"id": self._gen_id("folder"), "name": name}
        self._folders[(parent_id, name)] = folder
        self._files.setdefault(folder["id"], [])
        for filename, data in files_with_data:
            file = {"id": self._gen_id("file"), "name": filename, "mimeType": "image/jpeg"}
            self._files[folder["id"]].append(file)
            self._contents[file["id"]] = data
        return folder
