#!/usr/bin/env python3
"""Synchronize version.json with script-declared Version_local values."""

from __future__ import annotations

import json
import re
from collections import OrderedDict
from pathlib import Path
from typing import Dict, Iterable, Tuple

VERSION_PATTERN = re.compile(
    r"^\s*set\s+Version_local\s+to\s+\"(?P<version>[^\"]+)\"",
    re.MULTILINE,
)
SCRIPT_GLOB = "*.applescript"
MANIFEST_PATH = Path("version.json")
PLACEHOLDER_CHANGELOG = "Update this description for version {version}."


def find_version_declarations(root: Path) -> Dict[Path, str]:
    """Return mapping of script paths to declared Version_local strings."""

    matches: Dict[Path, str] = {}
    for script_path in sorted(root.rglob(SCRIPT_GLOB)):
        content = script_path.read_text(encoding="utf-8", errors="ignore")
        found = VERSION_PATTERN.findall(content)
        if not found:
            continue
        unique = {entry.strip() for entry in found}
        if len(unique) > 1:
            raise ValueError(
                f"Multiple Version_local values found in {script_path}: {sorted(unique)}"
            )
        matches[script_path] = unique.pop()
    if not matches:
        raise FileNotFoundError(
            "No Version_local declarations were found in any AppleScript files."
        )
    return matches


def ensure_versions_consistent(pairs: Iterable[Tuple[Path, str]]) -> str:
    """Ensure all discovered Version_local values match and return the version."""

    unique_versions = {version for _, version in pairs}
    if len(unique_versions) > 1:
        details = ", ".join(f"{path}: {version}" for path, version in pairs)
        raise ValueError(
            "Mismatched Version_local values detected across scripts: " + details
        )
    return unique_versions.pop()


def load_manifest(path: Path) -> OrderedDict:
    if not path.exists():
        raise FileNotFoundError("version.json must exist in the repository root.")
    return json.loads(path.read_text(encoding="utf-8"), object_pairs_hook=OrderedDict)


def ensure_manifest_entry(manifest: OrderedDict, version: str) -> bool:
    versions = manifest.get("versions")
    if not isinstance(versions, list):
        raise ValueError("version.json is expected to contain a 'versions' list.")

    target_index = None
    for index, entry in enumerate(versions):
        if not isinstance(entry, dict):
            raise ValueError("Each version entry must be an object with metadata.")
        if entry.get("hdhr_version") == version:
            target_index = index
            break

    changed = False
    if target_index is None:
        new_entry = OrderedDict(
            (
                ("hdhr_version", version),
                ("changelog", PLACEHOLDER_CHANGELOG.format(version=version)),
            )
        )
        versions.insert(0, new_entry)
        changed = True
    elif target_index != 0:
        entry = versions.pop(target_index)
        versions.insert(0, entry)
        changed = True

    return changed


def write_manifest(path: Path, manifest: OrderedDict) -> None:
    serialized = json.dumps(manifest, indent=4)
    path.write_text(serialized + "\n", encoding="utf-8")


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent.parent
    version_map = find_version_declarations(repo_root)
    version = ensure_versions_consistent(version_map.items())

    manifest = load_manifest(repo_root / MANIFEST_PATH)
    if ensure_manifest_entry(manifest, version):
        write_manifest(repo_root / MANIFEST_PATH, manifest)
        print(f"version.json updated to include Version_local {version}.")
    else:
        print("version.json already up to date with Version_local.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
