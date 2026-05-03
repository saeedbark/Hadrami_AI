"""DB dict → Pydantic entry + response-payload helpers.

These helpers live in one place so both ``/ask`` and ``/translate-phrase``
return structurally-identical ``Entry`` objects.
"""

from __future__ import annotations

from typing import Any

from ..schemas import Entry, ExamplePair
from .text_utils import collect_highlight_surfaces, find_hadrami_spans


def _example_pairs(raw: Any) -> list[ExamplePair] | None:
    if not isinstance(raw, list):
        return None
    return [
        ExamplePair(
            h=str(ex.get("h", "")),
            f=str(ex.get("f", "")),
        )
        for ex in raw
        if isinstance(ex, dict)
    ]


def entries_to_response(entries: list[dict]) -> list[Entry]:
    """Coerce raw Supabase rows into fully-populated ``Entry`` models."""
    out: list[Entry] = []
    for entry in entries:
        out.append(
            Entry(
                id=int(entry.get("id", 0)),
                word_vocalized=str(entry.get("word_vocalized", "")),
                word_clean=entry.get("word_clean"),
                root=entry.get("root"),
                pos=entry.get("pos"),
                fusha_equivalent=str(entry.get("fusha_equivalent", "")),
                definition=str(entry.get("definition", "")),
                region=entry.get("region", "General"),
                synonyms=entry.get("synonyms"),
                phonetic_variants=entry.get("phonetic_variants"),
                note=entry.get("note"),
                source=entry.get("source"),
                proverbs=entry.get("proverbs"),
                tags=entry.get("tags"),
                examples=_example_pairs(entry.get("examples")),
            )
        )
    return out


def finalize_ask_payload(
    answer: str,
    mode: str,
    entries: list[dict],
    *,
    answer_source: str = "model",
) -> dict[str, Any]:
    """Shape the dict that ``/ask`` and ``/chat`` serialize back to the client."""
    highlight_surfaces = collect_highlight_surfaces(entries)
    return {
        "answer": answer,
        "mode": mode,
        "answer_source": answer_source,
        "context": entries_to_response(entries),
        "highlight_surfaces": highlight_surfaces,
        "hadrami_spans": find_hadrami_spans(answer, highlight_surfaces),
    }
