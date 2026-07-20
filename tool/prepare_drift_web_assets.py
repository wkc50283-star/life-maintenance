from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import urllib.request


SQLITE3_VERSION = "3.4.0"
SQLITE3_WASM_SHA256 = (
    "41cf968998241465d8b1dfffb1eb60dd10c35de5022a3647e14174ea3af84143"
)
SQLITE3_RELEASES_API = (
    "https://api.github.com/repos/simolus3/sqlite3.dart/releases?per_page=100"
)
OUTPUT_PATH = Path("web/sqlite3.wasm")


def _headers() -> dict[str, str]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "life-maintenance-drift-assets",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GH_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def _download_json(url: str) -> object:
    request = urllib.request.Request(url, headers=_headers())
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def _find_asset_url() -> str:
    releases = _download_json(SQLITE3_RELEASES_API)
    if not isinstance(releases, list):
        raise RuntimeError("Unexpected sqlite3 release API response")

    for release in releases:
        if not isinstance(release, dict):
            continue
        if SQLITE3_VERSION not in str(release.get("tag_name", "")):
            continue
        assets = release.get("assets", [])
        if not isinstance(assets, list):
            continue
        for asset in assets:
            if not isinstance(asset, dict):
                continue
            if asset.get("name") == "sqlite3.wasm":
                url = asset.get("browser_download_url")
                if isinstance(url, str) and url:
                    return url

    raise RuntimeError(
        f"Could not find sqlite3.wasm for sqlite3 {SQLITE3_VERSION}"
    )


def _verify_asset(data: bytes) -> None:
    digest = hashlib.sha256(data).hexdigest()
    if digest != SQLITE3_WASM_SHA256:
        raise RuntimeError(
            "Downloaded sqlite3.wasm failed SHA-256 verification: "
            f"expected {SQLITE3_WASM_SHA256}, got {digest}"
        )


def main() -> None:
    asset_url = _find_asset_url()
    request = urllib.request.Request(
        asset_url,
        headers={"User-Agent": "life-maintenance-drift-assets"},
    )
    with urllib.request.urlopen(request, timeout=60) as response:
        data = response.read()

    if len(data) < 100_000:
        raise RuntimeError(
            f"Downloaded sqlite3.wasm is unexpectedly small: {len(data)} bytes"
        )

    _verify_asset(data)

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_PATH.write_bytes(data)
    print(
        f"Prepared {OUTPUT_PATH} ({len(data)} bytes) for sqlite3 "
        f"{SQLITE3_VERSION}"
    )


if __name__ == "__main__":
    main()
