#!/usr/bin/env python3
"""Automatically update CHANGELOG.md when core scripts change.

The script expects the following environment variables:
- BEFORE: the commit SHA before the merge (e.g. github.event.before)
- AFTER: the commit SHA after the merge (e.g. github.sha)
"""

from __future__ import annotations

import os
import subprocess
from collections import OrderedDict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List, Sequence, Set

TARGET_FILES = {"hdhr_VCR.applescript", "hdhr_VCR_lib.applescript"}
CHANGELOG_PATH = Path("CHANGELOG.md")


@dataclass
class CommitInfo:
    sha: str
    subject: str
    files: Sequence[str]


class GitError(RuntimeError):
    """Raised when a git command fails."""


def run_git_command(args: Sequence[str]) -> str:
    try:
        completed = subprocess.run(
            ["git", *args],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
    except subprocess.CalledProcessError as exc:  # pragma: no cover - defensive
        message = exc.stderr.strip() or exc.stdout.strip() or str(exc)
        raise GitError(f"git {' '.join(args)} failed: {message}") from exc
    return completed.stdout


def gather_commits(before: str, after: str) -> List[CommitInfo]:
    rev_output = run_git_command(["rev-list", "--reverse", f"{before}..{after}"])
    shas = [line.strip() for line in rev_output.splitlines() if line.strip()]
    commits: List[CommitInfo] = []
    for sha in shas:
        subject = run_git_command(["show", "-s", "--format=%s", sha]).strip()
        files_output = run_git_command(["diff-tree", "--no-commit-id", "--name-only", "-r", sha])
        files = [line.strip() for line in files_output.splitlines() if line.strip()]
        relevant = [f for f in files if f in TARGET_FILES]
        if relevant:
            commits.append(CommitInfo(sha=sha, subject=subject, files=relevant))
    return commits


def build_bullets(commits: Iterable[CommitInfo]) -> List[str]:
    seen: Set[str] = set()
    bullets: List[str] = []
    for commit in commits:
        touched = ", ".join(sorted(OrderedDict.fromkeys(commit.files)))
        bullet = f"- {touched}: {commit.subject} ({commit.sha[:7]})"
        if bullet not in seen:
            bullets.append(bullet)
            seen.add(bullet)
    return bullets


def ensure_changelog_exists() -> None:
    if not CHANGELOG_PATH.exists():
        raise FileNotFoundError("CHANGELOG.md must exist in the repository root")


def update_existing_entry(entry_text: str, bullets: Sequence[str]) -> str:
    import re

    updated_pattern = re.compile(r"(### Updated\n)(?P<body>(?:.*?))(?=(\n### |\Z))", re.DOTALL)
    match = updated_pattern.search(entry_text)
    if match:
        body = match.group("body")
        existing_lines = [line.strip() for line in body.splitlines() if line.strip()]
        existing_set = {line for line in existing_lines if line.startswith("- ")}
        new_lines = existing_lines[:]
        for bullet in bullets:
            bullet_line = bullet.strip()
            if bullet_line not in existing_set:
                new_lines.append(bullet_line)
                existing_set.add(bullet_line)
        body_text = "\n".join(new_lines)
        if body_text and not body_text.endswith("\n"):
            body_text += "\n"
        start = match.start("body")
        end = match.end("body")
        return entry_text[:start] + body_text + entry_text[end:]

    trimmed = entry_text.rstrip()
    section_body = "\n".join(bullets)
    if section_body and not section_body.endswith("\n"):
        section_body += "\n"
    return f"{trimmed}\n\n### Updated\n{section_body}"


def build_new_entry(date_stamp: str, bullets: Sequence[str]) -> str:
    body = "\n".join(bullets)
    if body and not body.endswith("\n"):
        body += "\n"
    return f"## {date_stamp}\n\n### Updated\n{body}"


def insert_entry(original: str, new_entry: str) -> str:
    original = original.strip()
    new_entry = new_entry.strip()
    if not original:
        return new_entry
    return f"{new_entry}\n\n{original}"


def update_changelog(bullets: Sequence[str]) -> bool:
    ensure_changelog_exists()
    content = CHANGELOG_PATH.read_text()
    header = "# Changelog"
    if not content.startswith(header):
        raise ValueError("CHANGELOG.md must start with '# Changelog'")

    remainder = content[len(header):].lstrip("\n")
    date_stamp = datetime.now(timezone.utc).strftime("%y%m%d")

    import re

    entry_pattern = re.compile(r"## (?P<date>\d{6})\n(?P<body>(?:.*?))(?=(\n## |\Z))", re.DOTALL)
    match = entry_pattern.match(remainder)

    if match and match.group("date") == date_stamp:
        entry_text = match.group(0)
        updated_entry = update_existing_entry(entry_text, bullets)
        remainder = updated_entry + remainder[len(entry_text):]
    else:
        new_entry = build_new_entry(date_stamp, bullets)
        remainder = insert_entry(remainder, new_entry)

    updated_content = f"{header}\n\n{remainder.strip()}\n"
    if content == updated_content:
        return False

    CHANGELOG_PATH.write_text(updated_content)
    return True


def main() -> int:
    before = os.environ.get("BEFORE")
    after = os.environ.get("AFTER") or os.environ.get("GITHUB_SHA")

    if not before or not after:
        print("BEFORE and AFTER environment variables are required to update the changelog.")
        return 0

    commits = gather_commits(before, after)
    if not commits:
        print("No relevant commits detected; changelog unchanged.")
        return 0

    bullets = build_bullets(commits)
    if not bullets:
        print("No new bullet entries produced; changelog unchanged.")
        return 0

    changed = update_changelog(bullets)
    if changed:
        print("CHANGELOG.md updated for core script changes.")
    else:
        print("Changelog already up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
