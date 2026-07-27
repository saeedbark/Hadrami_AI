"""Arabic text normalization + span detection for highlighting."""

from __future__ import annotations

import unicodedata
from typing import Any


def _normalize_match_char(ch: str) -> str:
    if ch in {"أ", "إ", "آ", "ٱ"}:
        return "ا"
    if ch == "ى":
        return "ي"
    if ch == "ـ":
        return ""
    if unicodedata.combining(ch):
        return ""
    return ch


def normalized_text_with_positions(text: str) -> tuple[str, list[int]]:
    """Return (normalized_text, map_from_normalized_idx_to_original_idx)."""
    chars: list[str] = []
    positions: list[int] = []
    for idx, ch in enumerate(text):
        norm = _normalize_match_char(ch)
        if not norm:
            continue
        chars.append(norm)
        positions.append(idx)
    return "".join(chars), positions


def synonyms_from_entry(entry: dict[str, Any]) -> list[str]:
    raw = entry.get("synonyms")
    if not isinstance(raw, list):
        return []
    return [x.strip() for x in raw if isinstance(x, str) and x.strip()]


def first_example(entry: dict[str, Any]) -> tuple[str, str]:
    raw_examples = entry.get("examples")
    if not isinstance(raw_examples, list):
        return "", ""
    for ex in raw_examples:
        if not isinstance(ex, dict):
            continue
        hadrami = str(ex.get("h") or "").strip()
        fusha = str(ex.get("f") or "").strip()
        if hadrami and fusha:
            return hadrami, fusha
    return "", ""


def collect_highlight_surfaces(entries: list[dict]) -> list[str]:
    """Return headword/clean/synonym strings that are safe to highlight.

    Sorted longest-first so that multi-token matches win over single-token
    substrings during the greedy-left-to-right scan.
    """
    seen: set[str] = set()
    surfaces: list[str] = []
    for entry in entries:
        for raw in [
            entry.get("word_vocalized"),
            entry.get("word_clean"),
            *synonyms_from_entry(entry),
        ]:
            text = str(raw or "").strip()
            if len(text) < 2 or text in seen:
                continue
            seen.add(text)
            surfaces.append(text)
    surfaces.sort(key=len, reverse=True)
    return surfaces


def find_hadrami_spans(text: str, surfaces: list[str]) -> list[dict[str, Any]]:
    """Return non-overlapping spans where any surface form occurs in ``text``.

    Matching is Arabic-normalized (alef-variants collapsed, tashkeel stripped)
    but offsets are remapped to the original Unicode positions so the Flutter
    client can use them as-is for RTL highlighting.
    """
    if not text or not surfaces:
        return []

    normalized_text, positions = normalized_text_with_positions(text)
    if not normalized_text:
        return []

    intervals: list[tuple[int, int]] = []
    for surface in surfaces:
        normalized_surface, _ = normalized_text_with_positions(surface)
        if len(normalized_surface) < 2:
            continue
        start_at = 0
        while True:
            idx = normalized_text.find(normalized_surface, start_at)
            if idx < 0:
                break
            orig_start = positions[idx]
            orig_end = positions[idx + len(normalized_surface) - 1] + 1
            intervals.append((orig_start, orig_end))
            start_at = idx + 1

    if not intervals:
        return []

    intervals.sort()
    merged: list[list[int]] = [[intervals[0][0], intervals[0][1]]]
    for start, end in intervals[1:]:
        last = merged[-1]
        if start <= last[1]:
            if end > last[1]:
                last[1] = end
            continue
        merged.append([start, end])

    return [
        {"start": start, "end": end, "surface": text[start:end]}
        for start, end in merged
        if start < end
    ]
