#!/usr/bin/env python3
"""Comprehensive dataset refactoring script.

1. Fix truncated arabic_fus7a entries
2. Merge true duplicate entries (same meaning)
3. Mark polysemous duplicates (different meanings) with sense notes
4. Extract usage examples from full_definition
5. Add fus7a_short field (concise 1-3 word gloss)
6. Add aliases where variant forms exist
7. Add version/metadata to root object
8. Reindex IDs and fix total count
"""
import copy
import io
import json
import re
import sys
from datetime import date

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

INPUT = "data/hadrami_dataset.json"
OUTPUT = "data/hadrami_dataset.json"
BACKUP = "data/hadrami_dataset.backup.json"

with open(INPUT, encoding="utf-8") as f:
    data = json.load(f)

entries: list[dict] = data["entries"]
print(f"Loaded {len(entries)} entries")


# ── 1. FIX TRUNCATED arabic_fus7a ──────────────────────────────────────
# The fus7a was truncated at ~50 chars in the CSV export.
# Strategy: if fus7a ends mid-word, try to complete it from full_definition.
def fix_truncated_fus7a(entry: dict) -> bool:
    fus7a = entry.get("arabic_fus7a", "").strip()
    defn = entry.get("full_definition", "").strip()
    if not fus7a or len(fus7a) < 15:
        return False

    last_char = fus7a[-1]
    ends_mid_word = last_char in "تضخصعغفقكلمنبحجدذرزسشطثظ"

    if not ends_mid_word:
        return False

    # Try to find the truncated text in the definition and complete it
    idx = defn.find(fus7a)
    if idx >= 0:
        rest = defn[idx + len(fus7a):]
        # Grab until next sentence boundary
        m = re.match(r"([^\n.،:!؟]+)", rest)
        if m:
            completed = fus7a + m.group(1).strip()
            entry["arabic_fus7a"] = completed.strip()
            return True

    # Fallback: the fus7a might not be a verbatim substring of definition
    # Try to find the last word fragment and complete it
    words = fus7a.split()
    if words:
        last_fragment = words[-1]
        idx2 = defn.find(last_fragment)
        if idx2 >= 0:
            rest2 = defn[idx2 + len(last_fragment):]
            m2 = re.match(r"(\S+)", rest2)
            if m2:
                completed_word = last_fragment + m2.group(1)
                entry["arabic_fus7a"] = fus7a[: -len(last_fragment)] + completed_word
                return True
    return False


# Known manual fixes for entries where auto-fix won't work
MANUAL_FUS7A_FIXES = {
    6: "تعبير عن التأكد الشديد والتضخيم والاستغراب",
    39: "اصمت - طلب الصمت",
    284: "الاحتفال عند نجاح موسم النخيل",
    309: "بيت صغير",
    340: "ذراع - وحدة قياس",
    414: "الغائط",
    449: "عقد كبير من الفضة للرأس",
    557: "بناء بالحجر حول البئر لحمايتها من الانهيار",
    674: "قطعة معدنية على الباب لإعلام صاحب البيت",
    768: "صندوق كبير لحفظ الملابس والأغراض الشخصية",
    792: "رأس التمرة",
    984: "رقصة شعبية يصاحبها عزف المزمار",
    925: "مقر عسكري صغير",
}

fus7a_fixed_auto = 0
for e in entries:
    if fix_truncated_fus7a(e):
        fus7a_fixed_auto += 1

fus7a_fixed_manual = 0
for e in entries:
    if e["id"] in MANUAL_FUS7A_FIXES:
        old = e["arabic_fus7a"]
        e["arabic_fus7a"] = MANUAL_FUS7A_FIXES[e["id"]]
        if old != e["arabic_fus7a"]:
            fus7a_fixed_manual += 1

print(f"Fixed {fus7a_fixed_auto} auto + {fus7a_fixed_manual} manual truncated fus7a entries")


# ── 2. HANDLE DUPLICATES ──────────────────────────────────────────────
# Merge true duplicates (same/overlapping meaning), keep polysemous (different meanings) with sense notes
MERGE_RULES = {
    # (word, action): "merge_first" = keep first entry with combined def,
    #                 "merge_second" = keep second entry with combined def,
    #                 "keep_both" = different senses, keep both and annotate
    "الخره": {
        "action": "merge",
        "keep_idx": 1,
        "combined_fus7a": "سقالة البناء - قطعة خشب معلقة بحبل",
        "combined_def": None,  # auto-combine
    },
    "الخيل": {
        "action": "keep_both",
        "sense_0": "شمروخ - غصن من العذق",
        "sense_1": "المشرف على توزيع المياه",
    },
    "الساقيه": {
        "action": "merge",
        "keep_idx": 0,
        "combined_fus7a": "قناة ري - مجرى الماء",
        "combined_def": None,
    },
    "القس": {
        "action": "keep_both",
        "sense_0": "مفتاح الكهرباء",
        "sense_1": "ما يبس من التمر وقسى",
    },
    "الكواه": {
        "action": "merge",
        "keep_idx": 1,
        "combined_fus7a": "المدخنة - فتحة لخروج الدخان",
        "combined_def": None,
    },
    "يولف": {
        "action": "keep_both",
        "sense_0": "التوليف - إصلاح بتجميع قطع",
        "sense_1": "يعتاد - يألف المكان",
    },
}

# Build word->indices map
word_indices: dict[str, list[int]] = {}
for i, e in enumerate(entries):
    w = e["hadrami_word"].strip()
    word_indices.setdefault(w, []).append(i)

indices_to_remove: set[int] = set()
merged_count = 0
annotated_count = 0

for word, indices in word_indices.items():
    if len(indices) < 2:
        continue
    if word not in MERGE_RULES:
        continue

    rule = MERGE_RULES[word]
    idx0, idx1 = indices[0], indices[1]
    e0, e1 = entries[idx0], entries[idx1]

    if rule["action"] == "merge":
        keep_idx_rel = rule["keep_idx"]
        keep_abs = [idx0, idx1][keep_idx_rel]
        remove_abs = [idx0, idx1][1 - keep_idx_rel]
        keep_e = entries[keep_abs]
        remove_e = entries[remove_abs]

        keep_e["arabic_fus7a"] = rule["combined_fus7a"]
        if rule.get("combined_def") is None:
            # Auto-combine: append the other definition
            sep = "\n---\n" if len(keep_e["full_definition"]) > 40 else " | "
            keep_e["full_definition"] = (
                keep_e["full_definition"].rstrip(".") + sep + remove_e["full_definition"]
            )
        else:
            keep_e["full_definition"] = rule["combined_def"]

        indices_to_remove.add(remove_abs)
        merged_count += 1

    elif rule["action"] == "keep_both":
        e0["arabic_fus7a"] = rule["sense_0"]
        e1["arabic_fus7a"] = rule["sense_1"]
        annotated_count += 1

# Remove merged entries (in reverse to preserve indices)
entries_clean = [e for i, e in enumerate(entries) if i not in indices_to_remove]
print(f"Merged {merged_count} duplicate pairs, annotated {annotated_count} polysemous pairs")
print(f"Entries after dedup: {len(entries_clean)}")
entries = entries_clean


# ── 3. EXTRACT EXAMPLES FROM full_definition ──────────────────────────
# Pattern: Hadrami uses reversed parens ) ... ( for inline examples
# Also match ) : text ( pattern
EXAMPLE_PATTERN = re.compile(
    r"\)\s*:?\s*([^()]{4,80}?)\s*\(",
    re.UNICODE
)


def extract_examples(defn: str) -> list[dict]:
    """Extract usage examples from the definition text."""
    matches = EXAMPLE_PATTERN.findall(defn)
    examples = []
    seen = set()
    for m in matches:
        text = m.strip().rstrip("،. ")
        if text and text not in seen and len(text) >= 4:
            seen.add(text)
            examples.append({"hadrami": text, "fusha": ""})
    return examples


examples_added = 0
for e in entries:
    existing = e.get("examples")
    if existing:
        continue
    extracted = extract_examples(e.get("full_definition", ""))
    if extracted:
        e["examples"] = extracted
        examples_added += 1

print(f"Extracted examples for {examples_added} entries")


# ── 4. ADD fus7a_short ────────────────────────────────────────────────
# A concise 1-3 word gloss derived from arabic_fus7a
def make_fus7a_short(fus7a: str) -> str:
    """Create a short 1-3 word MSA gloss from the full fus7a."""
    clean = fus7a.strip()
    if not clean:
        return ""

    # Remove "وهو/وهي" prefix
    clean = re.sub(r"^(وهو|وهي|أي|يعني)\s+", "", clean)

    # If already short enough (<=30 chars), use as-is
    if len(clean) <= 30:
        return clean

    # Take text before first dash, comma, or long connector
    for sep in [" - ", " – ", "،", " أو ", " أي "]:
        if sep in clean:
            part = clean.split(sep, 1)[0].strip()
            if len(part) >= 3:
                return part

    # Take first 3 words
    words = clean.split()
    short = " ".join(words[:3])
    return short


fus7a_short_added = 0
for e in entries:
    if e.get("fus7a_short"):
        continue
    short = make_fus7a_short(e.get("arabic_fus7a", ""))
    if short and short != e.get("arabic_fus7a", "").strip():
        e["fus7a_short"] = short
        fus7a_short_added += 1

print(f"Added fus7a_short to {fus7a_short_added} entries")


# ── 5. ADD ALIASES ────────────────────────────────────────────────────
# Entries with variant forms in hadrami_word (comma or slash separated)
def extract_aliases(word: str) -> tuple[str, list[str]]:
    """Split 'أثره ، أثرك' into primary word and aliases."""
    separators = [" ، ", " / ", " أو "]
    for sep in separators:
        if sep in word:
            parts = [p.strip() for p in word.split(sep) if p.strip()]
            if len(parts) >= 2:
                return parts[0], parts[1:]
    # Also handle "اسم :او اسم" pattern
    if " :او " in word or " او " in word:
        sep2 = " :او " if " :او " in word else " او "
        parts = [p.strip() for p in word.split(sep2) if p.strip()]
        if len(parts) >= 2:
            return parts[0], parts[1:]
    return word, []


aliases_added = 0
for e in entries:
    if e.get("aliases"):
        continue
    primary, aliases = extract_aliases(e["hadrami_word"])
    if aliases:
        e["hadrami_word"] = primary
        e["aliases"] = aliases
        aliases_added += 1

print(f"Added aliases to {aliases_added} entries")


# ── 6. CLEAN UP WHITESPACE AND FORMATTING ─────────────────────────────
def clean_text(text: str) -> str:
    """Normalize Arabic text: fix spacing around parens, trim, collapse whitespace."""
    t = text.strip()
    t = re.sub(r"\s+", " ", t)
    # Remove trailing period-only definitions
    if t == ".":
        return ""
    return t


for e in entries:
    e["hadrami_word"] = clean_text(e.get("hadrami_word", ""))
    e["arabic_fus7a"] = clean_text(e.get("arabic_fus7a", ""))
    e["full_definition"] = e.get("full_definition", "").strip()

# Remove entries with empty hadrami_word
before = len(entries)
entries = [e for e in entries if e.get("hadrami_word", "").strip()]
removed_empty = before - len(entries)
if removed_empty:
    print(f"Removed {removed_empty} entries with empty hadrami_word")


# ── 7. REINDEX IDs ────────────────────────────────────────────────────
for i, e in enumerate(entries):
    e["id"] = i + 1


# ── 8. BUILD FINAL OUTPUT ─────────────────────────────────────────────
# Ensure consistent field order for each entry
def normalize_entry(e: dict) -> dict:
    out = {
        "id": e["id"],
        "hadrami_word": e["hadrami_word"],
        "arabic_fus7a": e["arabic_fus7a"],
        "full_definition": e["full_definition"],
    }
    if e.get("fus7a_short"):
        out["fus7a_short"] = e["fus7a_short"]
    if e.get("aliases"):
        out["aliases"] = e["aliases"]
    if e.get("examples"):
        out["examples"] = e["examples"]
    return out


final_entries = [normalize_entry(e) for e in entries]

output = {
    "version": "1.1.0",
    "updated": str(date.today()),
    "description": "Hadrami dialect dictionary - Arabic Fusha equivalents with examples",
    "total": len(final_entries),
    "entries": final_entries,
}

# ── 9. SAVE ───────────────────────────────────────────────────────────
# Create backup first
import shutil

shutil.copy2(INPUT, BACKUP)
print(f"Backup saved to {BACKUP}")

with open(OUTPUT, "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\nFinal dataset: {len(final_entries)} entries saved to {OUTPUT}")
print(f"New fields coverage:")
with_short = sum(1 for e in final_entries if e.get("fus7a_short"))
with_examples = sum(1 for e in final_entries if e.get("examples"))
with_aliases = sum(1 for e in final_entries if e.get("aliases"))
print(f"  fus7a_short: {with_short}/{len(final_entries)}")
print(f"  examples:    {with_examples}/{len(final_entries)}")
print(f"  aliases:     {with_aliases}/{len(final_entries)}")
