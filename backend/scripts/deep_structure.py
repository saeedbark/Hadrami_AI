#!/usr/bin/env python3
"""Deep semantic structuring for the Hadrami dialect dataset.

Adds:  part_of_speech, thematic_category, proverb_record,
       cultural_note, is_archaic.
Fills: all null / empty example fusha values.
Fixes: trailing punctuation, Arabic comma consistency.
"""

import json
import re
from pathlib import Path

DATA_PATH = Path(__file__).resolve().parent.parent / "data" / "hadrami_dataset.json"

# ────────────────────────────────────────────────────────────
# TEXT UTILITIES
# ────────────────────────────────────────────────────────────

def standardize_punct(s):
    if not isinstance(s, str):
        return s
    s = s.replace(",", "\u060C")
    s = re.sub(r"\s+", " ", s).strip()
    s = re.sub(r"\s+([،؛:!؟.\)])", r"\1", s)
    s = re.sub(r"([\(\[\{«])\s+", r"\1", s)
    s = re.sub(r"،\s*", "، ", s)
    s = re.sub(r"\s+\.", ".", s)
    return re.sub(r"\s+", " ", s).strip()


def clean_trailing(s):
    if not isinstance(s, str) or not s.strip():
        return s
    s = standardize_punct(s)
    s = re.sub(r"[،\s:]+$", "", s)
    if s and s[-1] not in ".،؟!؛)":
        s += "."
    return s


# ────────────────────────────────────────────────────────────
# 1.  PART-OF-SPEECH CLASSIFICATION
# ────────────────────────────────────────────────────────────

_EXPR_FUSHA_KW = [
    "تعبير", "لفظ", "أداة", "كناية", "للتعجب", "للنفي",
    "للتأكيد", "للمبالغة", "للاندهاش", "للتضخيم", "للاستغراب",
    "للتأوه", "للتحسر", "وعيد", "تهديد", "نداء",
]

_EXPR_DEF_KW = [
    "تأتي بمعنى", "تستعمل بمعنى", "وهي للنفي", "وهو للنفي",
    "كلمة تقال", "عبارة تقال", "لفظه لا معنى",
    "وهي لفظه", "أداة إشارة",
]

_EXPR_WORDS = {
    "أبدا", "أبب", "واه", "ليش", "لاما", "عاد", "عادك", "وراك",
    "حنا", "ويش", "عا", "لي", "آل", "أثره", "أثرك", "لمان",
    "يابوي", "يابوياه", "أح", "إكّس", "لا حد", "عاده", "مني",
}

_PARTICLE_FUSHAS = {
    "لماذا", "ماذا", "نحن", "على", "إلى", "إلى أن", "إذا لم",
    "الذي", "ماذا بك", "ماذا يقربلك", "لا أحد", "تأتي بمعنى الذي",
}

_VERB_STARTS = [
    "ابتلع", "اشتكى", "ذهب", "جرى", "ركض", "أسرع", "رمى", "أرم",
    "قبض", "أرسل", "تنحى", "ابتعد", "تحير", "عجز", "سار", "جهز",
    "نشر", "أصلح", "وجد", "صعق", "اشتد", "خاف", "فزع", "ضرب",
    "قطع", "بلل", "حرق", "كسر", "لسع", "غلب", "ألغ", "عصب",
    "يعتاد", "يألف", "يعجب", "يركض", "ينشبك", "ينشر",
    "لا تزال", "لا يزال", "أرسله", "قبضه", "صعقته",
    "ذهب صباحا", "سار فجرا", "تنحى وابتعد", "تحير وعجز",
    "جرى وركض", "جهز البيت",
    "تذهب", "تزرع", "تمهل", "تستحي", "تؤلمه", "توجعه",
    "استتر", "يستتر", "يختبئ", "انظر", "تأمل", "أمشي",
    "يمشي", "يجري", "يخاف", "يفزع", "ينفع", "يصلح",
    "يبتعد", "يتنح", "يجتنب", "نشّف", "يدوس", "دوس",
    "ادعس", "تغير", "خلط", "عصر", "طحن", "نفخ", "شد",
    "حفر", "غمق", "جمع", "حفظ", "تخزين", "رفع", "سحب",
    "فتح", "أغلق", "وصد", "صنع", "يصنع", "بنى", "يبني",
    "نقل", "حمل", "يحمل", "شرب", "يشرب", "ضحك", "يضحك",
]

_ADJ_INDICATORS = [
    "غير صالح", "غير كفوء", "ليس ناضح", "طيب ومؤدب",
    "فاضي بدون عمل", "المتكبر", "صفة لل",
]

_PRON_STARTS = ("بتشديد", "بكسر", "بفتح", "بالضم", "بتسكين", "بتخفيف")


def classify_pos(entry):
    word = (entry.get("hadrami_word") or "").strip()
    fusha = (entry.get("arabic_fus7a") or "").strip()
    defn = (entry.get("full_definition") or "").strip()

    # ── Expression ──
    if word in _EXPR_WORDS:
        return "Expression"
    for kw in _EXPR_FUSHA_KW:
        if kw in fusha:
            return "Expression"
    for kw in _EXPR_DEF_KW:
        if kw in defn:
            return "Expression"
    if fusha in _PARTICLE_FUSHAS:
        return "Expression"
    if " " in word and not word.startswith("ال"):
        is_compound_noun = any(
            word.startswith(p) for p in
            ["أم ", "أبو ", "جبل ", "بيت ", "زنبع ", "النزح ", "الغرة ",
             "اللبان ", "لخيبعان", "الخطاف"]
        )
        if not is_compound_noun:
            if any(kw in fusha + defn for kw in
                   ["بمعنى", "تعبير", "أداة", "كلمة", "كناية"]):
                return "Expression"

    # ── Verb ──
    for vs in _VERB_STARTS:
        if fusha == vs or fusha.startswith(vs):
            return "Verb"
    if word.startswith("ي") and len(word) >= 3 and not word.startswith("يا"):
        return "Verb"

    # Present-tense prefixes in fusha (ت/ي/ن + root = verb form)
    fusha_no_al = fusha.lstrip("ال")
    if fusha and not fusha.startswith("ال") and len(fusha) >= 3:
        if fusha[0] in "تينأ" and not any(fusha.startswith(n) for n in
                ["تعبير", "تقاليد", "تحية", "تمر", "نخل", "نبات", "أداة",
                 "نسب", "أرض", "نحن", "أثاث"]):
            return "Verb"

    for prefix in ["أي بمعنى ", "بمعنى ", "أي "]:
        if defn.startswith(prefix):
            after = defn[len(prefix):].split("،")[0].split(".")[0].split("(")[0].strip()
            if after and not after.startswith("ال") and not after.startswith("وه") and len(after) < 40:
                return "Verb"

    # Look for "بمعنى" ANYWHERE in the definition (not just start)
    m_meaning = re.search(r"بمعنى\s+([^،.\)\(]{2,40})", defn)
    if m_meaning:
        after = m_meaning.group(1).strip()
        if after and not after.startswith("ال") and not after.startswith("وه"):
            if not word.startswith("ال"):
                return "Verb"

    stripped = re.sub(r"[\u064B-\u0652\u0670]", "", word)
    if 2 <= len(stripped) <= 4 and not word.startswith("ال") and not word.startswith("إ"):
        for vs in _VERB_STARTS:
            if fusha.startswith(vs):
                return "Verb"

    # ── Adjective ──
    for ai in _ADJ_INDICATORS:
        if ai in fusha or ai in defn:
            return "Adjective"

    return "Noun"


# ────────────────────────────────────────────────────────────
# 2.  THEMATIC CATEGORY
# ────────────────────────────────────────────────────────────

_CAT_KW = {
    "Agriculture": [
        "نخل", "نخيل", "تمر", "تمور", "زراع", "مزرع", "بئر", "آبار",
        "غرس", "شتل", "حصاد", "محصول", "قمح", "بلح", "سمسم", "جلجل",
        "الري", "زرع", "ثمر", "حبوب", "طحين", "جريد", "سعف", "عذق",
        "شمروخ", "خصب", "سقي", "ساقي", "سواقي", "دلو", "حوض",
        "ماشية", "بهائم", "رعي", "علف", "قصب", "أغنام", "تسميد",
        "دواب", "إبل", "ثيران", "أبقار", "عسل", "فسيل", "تلقيح",
        "جربة", "نبق", "دوم", "سدر", "أثل", "لبان", "غصن",
        "روث", "دمان", "نضوج", "فسائل", "جداد", "حطب",
        "النخلة", "التمرة", "الأرض الزراعية",
    ],
    "Social Customs": [
        "زواج", "عرس", "قبيلة", "رقصة", "غناء", "تقاليد", "عادات",
        "احتفال", "بخور", "عريس", "عروس", "وليمة",
        "تفاخر", "مهر", "خطوبة", "زفين", "طقوس",
        "مناسبات", "كوفية", "علماء", "قضاة", "أشراف", "ختان",
        "نفاس", "ولادة", "مسجد", "وضوء", "صلاة", "أذان",
        "خطبة", "نكاح", "تحية", "ضيافة",
        "قبيل", "نسب", "شيخ", "نصرة", "هوكة", "أفراح",
    ],
    "Emotions": [
        "حزين", "غاضب", "غضب", "خائف", "خوف", "الحب", "كراهية", "زعلان",
        "دهشة", "استغراب", "تحسر", "تأوه", "فزع", "إعجاب",
        "مبالغة", "اندهاش",
        "ألم", "تألم", "خجل", "حيرة", "ورطة",
        "تكبر", "إحساس", "بكاء",
        "صراخ", "إزعاج", "ندامة", "خيبة",
        "قهر", "غيبة", "الزعل", "التحسر",
    ],
    "Nature": [
        "جبل", "بحر", "شمس", "مطر", "حيوان", "طائر",
        "حشر", "سحاب", "ضباب", "سيل", "ظلام", "فجر", "ريح",
        "نبات", "شجر", "ثعلب", "عنكبوت", "قرد", "نحل", "بومة",
        "جراد", "أرض", "سماء", "ليل", "صقور", "نسور", "حمام",
        "صحراء", "رمل", "وادي", "عيزا", "حداة", "ثعبان",
        "عقرب", "غبار", "برق", "رعد",
    ],
    "Daily Life": [
        "بيت", "منزل", "مترل", "طبخ", "أكل", "طعام", "ملابس",
        "فراش", "مطبخ", "وعاء", "فانوس", "كهرباء", "غسل",
        "نوم", "باب", "غرفة", "سقف", "جدار", "مخزن", "قماش",
        "حزام", "وشاح", "مقلاة", "وسادة", "مخدة", "تنار", "خبز",
        "دولاب", "كيس", "سوق", "جيب", "قميص", "حبل", "سيارة",
        "لمبة", "مفتاح", "ثياب", "فرش", "أثاث", "مفرش",
        "حجام", "ممرض", "سكين", "ملح", "فلفل", "بيض", "سمك",
        "لحم", "أداة", "خوص", "طين", "فخار", "حديد", "خشب",
        "صندوق", "ماء", "دار", "طبق", "قدر", "فطور", "شاي",
        "قهوة", "كتاب", "لعب", "كرة", "بناء", "النورة",
    ],
}


def classify_thematic(entry):
    blob = " ".join(
        str(entry.get(f, ""))
        for f in ("arabic_fus7a", "full_definition", "hadrami_word")
    )
    scores = {}
    for cat, kws in _CAT_KW.items():
        score = 0
        for kw in kws:
            if len(kw) <= 3:
                if f" {kw} " in f" {blob} " or f" {kw}." in blob or f" {kw}،" in blob:
                    score += 1
            else:
                if kw in blob:
                    score += 1
        scores[cat] = score
    priority = ["Nature", "Agriculture", "Social Customs", "Emotions", "Daily Life"]
    best = max(scores, key=lambda k: (scores[k], -priority.index(k)))
    return best if scores[best] > 0 else "Daily Life"


# ────────────────────────────────────────────────────────────
# 3.  PROVERB EXTRACTION
# ────────────────────────────────────────────────────────────

_PROVERB_LABEL = (
    r"و?المثل\s+(?:القائل|يقول|الآخر\s+القائل|العربي\s+القائل)"
)

_PROVERB_RE = re.compile(
    _PROVERB_LABEL + r"\s*\)\s*:?\s*(.*?)\(", re.DOTALL
)
_PROVERB_COLON_RE = re.compile(
    _PROVERB_LABEL + r"\s*:\s*\)?\s*(.*?)\(?(?:[.،]|$)", re.DOTALL
)
_PROVERB_BLOCK_RE = re.compile(
    r"(?:، )?" + _PROVERB_LABEL + r"[^.]*\.", re.DOTALL
)


def extract_proverbs(definition):
    if not isinstance(definition, str):
        return [], definition

    proverbs = []
    for m in _PROVERB_RE.finditer(definition):
        txt = m.group(1).strip()
        if txt:
            proverbs.append(txt)

    if not proverbs:
        for m in _PROVERB_COLON_RE.finditer(definition):
            txt = m.group(1).strip()
            if txt:
                proverbs.append(txt)

    cleaned = _PROVERB_BLOCK_RE.sub("", definition) if proverbs else definition
    cleaned = re.sub(r"، [،\s]*\.", ".", cleaned)
    cleaned = clean_trailing(cleaned)

    seen, unique = set(), []
    for p in proverbs:
        p2 = standardize_punct(p).strip(".")
        if p2 and p2 not in seen:
            seen.add(p2)
            unique.append(p2)
    return unique, cleaned


# ────────────────────────────────────────────────────────────
# 4.  CULTURAL NOTE EXTRACTION
# ────────────────────────────────────────────────────────────

_CULTURAL_STARTS = [
    "يقول الشاعر", "قال الشاعر", "كقول الشاعر",
    "وهي تختلف حسب", "تختلف حسب المنطقة",
    "في لهجة أخرى", "وفي لهجة أخرى",
    "أهل البادية", "في الساحل خاصة",
    "وهي تعتبر لفظ", "من الكلمات التي يستعملها",
    "والذال تحول", "ينطق الجيم بالياء",
    "وتنطق منونة",
]


def extract_cultural_note(definition):
    if not isinstance(definition, str):
        return None, definition

    for cs in _CULTURAL_STARTS:
        idx = definition.find(cs)
        if idx > 0:
            before = definition[:idx].rstrip("، .")
            after = definition[idx:]
            if before and len(before) >= 10:
                return clean_trailing(after), clean_trailing(before)
    return None, definition


# ────────────────────────────────────────────────────────────
# 5.  ARCHAIC DETECTION
# ────────────────────────────────────────────────────────────

_ARCHAIC_KW = [
    "انقرض", "ثم انقرض", "لم تعد تستخدم", "لم يعد يستخدم",
    "كانت تستخدم", "كان يستخدم", "كان يلبسه",
    "نادر الاستعمال", "مهجور", "اندثر", "اندثرت",
    "لفظه مستحدثه",
]


def detect_archaic(entry):
    blob = "{} {}".format(
        entry.get("full_definition", ""),
        entry.get("cultural_note", ""),
    )
    return any(kw in blob for kw in _ARCHAIC_KW)


# ────────────────────────────────────────────────────────────
# 6.  FUSHA FILLING
# ────────────────────────────────────────────────────────────

def infer_fusha(entry):
    defn = entry.get("full_definition") or ""
    fusha = entry.get("arabic_fus7a") or ""
    short = entry.get("fus7a_short") or ""

    fusha_is_pron = any(fusha.startswith(k) for k in _PRON_STARTS)

    candidates = []
    if not fusha_is_pron and fusha:
        candidates.append(fusha)
    if short:
        candidates.append(short)

    for pat in [
        r"(?:أي|يعني|بمعنى)\s+([^،.\)\(]{2,80})",
        r"^وهو\s+([^،.]{2,60})",
        r"^وهي\s+([^،.]{2,60})",
        r"^هو\s+([^،.]{2,60})",
        r"^هي\s+([^،.]{2,60})",
    ]:
        m = re.search(pat, defn)
        if m:
            ex = m.group(1).strip()
            if ex and not any(ex.startswith(k) for k in _PRON_STARTS):
                candidates.append(ex)
                break

    first_sent = defn.split("،")[0].split(".")[0].strip()
    if first_sent and len(first_sent) < 100:
        candidates.append(first_sent)

    for c in candidates:
        c = standardize_punct(c).strip(".")
        if c and len(c) < 120 and not any(c.startswith(k) for k in _PRON_STARTS):
            return c
    return None


def fill_example_fusha(entry, stats):
    examples = entry.get("examples")
    if not isinstance(examples, list):
        return

    translation = infer_fusha(entry)
    for ex in examples:
        if not isinstance(ex, dict):
            continue
        fv = ex.get("fusha")
        if fv is None or (isinstance(fv, str) and fv.strip() == ""):
            if translation:
                ex["fusha"] = translation
                stats["fusha_filled"] += 1
            else:
                ex["fusha"] = None


# ────────────────────────────────────────────────────────────
# MAIN PIPELINE
# ────────────────────────────────────────────────────────────

def process_entry(entry, stats):
    for field in ("hadrami_word", "arabic_fus7a", "full_definition", "fus7a_short"):
        if field in entry and isinstance(entry[field], str):
            entry[field] = standardize_punct(entry[field])
    if "full_definition" in entry:
        entry["full_definition"] = clean_trailing(entry["full_definition"])

    entry["part_of_speech"] = classify_pos(entry)
    entry["thematic_category"] = classify_thematic(entry)

    proverbs, cleaned = extract_proverbs(entry.get("full_definition", ""))
    if proverbs:
        entry["proverb_record"] = proverbs
        entry["full_definition"] = cleaned

    cultural, cleaned = extract_cultural_note(entry.get("full_definition", ""))
    if cultural:
        entry["cultural_note"] = cultural
        entry["full_definition"] = cleaned

    fill_example_fusha(entry, stats)

    entry["is_archaic"] = detect_archaic(entry)

    if entry.get("full_definition"):
        entry["full_definition"] = clean_trailing(entry["full_definition"])

    # Reorder keys for readability
    ordered = {}
    key_order = [
        "id", "hadrami_word", "arabic_fus7a", "full_definition",
        "fus7a_short", "search_key", "part_of_speech", "thematic_category",
        "is_archaic", "pronunciation_notes", "proverb_record",
        "cultural_note", "examples", "aliases",
    ]
    for k in key_order:
        if k in entry:
            ordered[k] = entry[k]
    for k in entry:
        if k not in ordered:
            ordered[k] = entry[k]
    return ordered


_PRON_PREFIX_RE = re.compile(
    r"^\s*(?:\(?\s*)?(بتشديد|بكسر|بفتح|بالضم|بتسكين|بتخفيف|كسر|فتح|ضم"
    r"|مكسور|مفتوح|مضموم|ساكن|الياء\s+مكسور|الراء\s+ينطق\s+بالتخفيف)"
    r"[^،\.]*\s*[،\.]\s*"
)
_PRON_INLINE_RE = re.compile(
    r"\(\s*(بتشديد|بكسر|بفتح|بالضم|بتسكين|بتخفيف|كسر|فتح|ضم)[^)]{0,80}\)"
)
_PRON_COMMA_RE = re.compile(
    r"،\s*((?:بتشديد|بكسر|بفتح|بالضم|بتسكين|بتخفيف|كسر|فتح|ضم)[^،\.]{0,80})(?=[،\.])"
)


def _normalize_for_compare(s):
    s = standardize_punct(s or "")
    s = re.sub(r"[أإآٱ]", "ا", s)
    return re.sub(r"\s+", " ", s).strip()


def _extract_pron_notes(defn):
    if not isinstance(defn, str):
        return defn, []
    notes, text = [], defn
    m = _PRON_PREFIX_RE.match(text)
    if m:
        notes.append(standardize_punct(m.group(0).strip(" ،.")))
        text = text[m.end():]
    for m2 in list(_PRON_INLINE_RE.finditer(text)):
        n = standardize_punct(m2.group(0).strip("() "))
        if n:
            notes.append(n)
    text = _PRON_INLINE_RE.sub("", text)
    for m3 in list(_PRON_COMMA_RE.finditer(text)):
        n = standardize_punct(m3.group(1))
        if n:
            notes.append(n)
    text = _PRON_COMMA_RE.sub("", text)
    seen, unique = set(), []
    for n in notes:
        n2 = standardize_punct(n)
        if n2 and n2 not in seen:
            seen.add(n2)
            unique.append(n2)
    return standardize_punct(text), unique


def _fix_split_words(s):
    if not isinstance(s, str):
        return s
    s = s.replace("المطحون افف", "المطحون الجاف")
    s = s.replace("اليابس أو افف", "اليابس أو المجفف")
    s = s.replace("أو افف", "أو المجفف")
    s = s.replace(" افف.", " المجفف.")
    return s


def pass1_cleanup(entry):
    """First-pass: search_key, pronunciation_notes, split words, basic fusha fill."""
    for field in ("hadrami_word", "arabic_fus7a", "full_definition", "fus7a_short"):
        if field in entry and isinstance(entry[field], str):
            entry[field] = standardize_punct(_fix_split_words(entry[field]))

    if "aliases" in entry and isinstance(entry["aliases"], list):
        entry["aliases"] = [standardize_punct(a) for a in entry["aliases"] if isinstance(a, str)]

    fd = entry.get("full_definition")
    cleaned_fd, notes = _extract_pron_notes(fd)
    if isinstance(fd, str):
        entry["full_definition"] = cleaned_fd
    if notes:
        existing = entry.get("pronunciation_notes")
        existing = existing if isinstance(existing, list) else []
        seen = set(existing)
        for n in notes:
            if n not in seen:
                seen.add(n)
                existing.append(n)
        if existing:
            entry["pronunciation_notes"] = existing

    entry["search_key"] = _normalize_for_compare(entry.get("hadrami_word", ""))

    if "examples" in entry and isinstance(entry["examples"], list):
        for ex in entry["examples"]:
            if not isinstance(ex, dict):
                continue
            if isinstance(ex.get("hadrami"), str):
                ex["hadrami"] = standardize_punct(ex["hadrami"])
            fv = ex.get("fusha")
            if isinstance(fv, str):
                fv = standardize_punct(fv)
            if fv == "":
                fusha_cand = entry.get("arabic_fus7a") or entry.get("fus7a_short")
                if fusha_cand and not any(fusha_cand.startswith(k) for k in _PRON_STARTS):
                    ex["fusha"] = standardize_punct(fusha_cand)
                else:
                    ex["fusha"] = None
            else:
                ex["fusha"] = fv if fv not in (None, "") else None

    return entry


def main():
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    entries = data.get("entries", [])

    for entry in entries:
        pass1_cleanup(entry)

    stats = {
        "pos": {},
        "thematic": {},
        "proverbs_extracted": 0,
        "cultural_notes_added": 0,
        "fusha_filled": 0,
        "archaic_count": 0,
    }

    processed = []
    for entry in entries:
        e = process_entry(entry, stats)
        processed.append(e)
        stats["pos"][e["part_of_speech"]] = stats["pos"].get(e["part_of_speech"], 0) + 1
        stats["thematic"][e["thematic_category"]] = stats["thematic"].get(e["thematic_category"], 0) + 1
        if e.get("proverb_record"):
            stats["proverbs_extracted"] += len(e["proverb_record"])
        if e.get("cultural_note"):
            stats["cultural_notes_added"] += 1
        if e.get("is_archaic"):
            stats["archaic_count"] += 1

    null_fusha = sum(
        1 for e in processed
        for ex in (e.get("examples") or [])
        if isinstance(ex, dict) and ex.get("fusha") is None
    )
    stats["remaining_null_fusha"] = null_fusha

    data["entries"] = processed
    DATA_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(stats, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
