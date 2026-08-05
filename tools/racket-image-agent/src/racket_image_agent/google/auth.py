"""Autenticacao Google, via service account OU OAuth (usuario autorizado).

Nunca gravamos credenciais no repositorio. As credenciais vem de:
  1. GOOGLE_CREDENTIALS_JSON - o conteudo JSON completo da credencial
     (service account ou "authorized user"), tipicamente injetado por um
     secret manager (Cloud Run, GitHub Actions secrets, etc.).
  2. GOOGLE_APPLICATION_CREDENTIALS - caminho para um arquivo local com o
     mesmo conteudo (uso local / cron Linux).

Permissoes minimas recomendadas (ver README "Autenticacao e permissoes"):
  - Drive: acesso de Editor/Content Manager APENAS a pasta "Fotos
    E-commerce" (ou ao Shared Drive que a contem). Como o agente precisa
    enxergar pastas pre-existentes (nao apenas as que ele mesmo cria), o
    escopo de API usado e `drive` (completo) - restrinja o *raio de acao*
    compartilhando com a service account somente a pasta/Shared Drive
    necessaria, em vez de todo o Drive do usuario.
  - Sheets: `spreadsheets.readonly` - o agente so le o catalogo, nunca
    escreve na planilha.
"""
from __future__ import annotations

import json
import os
from typing import List, Optional

from google.oauth2 import service_account
from google.oauth2.credentials import Credentials as UserCredentials

DRIVE_SCOPE = "https://www.googleapis.com/auth/drive"
SHEETS_READONLY_SCOPE = "https://www.googleapis.com/auth/spreadsheets.readonly"
DEFAULT_SCOPES = [DRIVE_SCOPE, SHEETS_READONLY_SCOPE]


class CredentialsNotConfiguredError(RuntimeError):
    pass


def _credentials_from_info(info: dict, scopes: List[str]):
    if info.get("type") == "service_account":
        return service_account.Credentials.from_service_account_info(info, scopes=scopes)
    return UserCredentials.from_authorized_user_info(info, scopes=scopes)


def load_credentials(scopes: Optional[List[str]] = None):
    scopes = scopes or DEFAULT_SCOPES

    raw_json = os.environ.get("GOOGLE_CREDENTIALS_JSON")
    if raw_json:
        info = json.loads(raw_json)
        return _credentials_from_info(info, scopes)

    key_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS")
    if key_path and os.path.exists(key_path):
        with open(key_path, "r", encoding="utf-8") as f:
            info = json.load(f)
        return _credentials_from_info(info, scopes)

    raise CredentialsNotConfiguredError(
        "Credenciais do Google nao configuradas. Defina GOOGLE_CREDENTIALS_JSON "
        "(conteudo JSON) ou GOOGLE_APPLICATION_CREDENTIALS (caminho de arquivo)."
    )
