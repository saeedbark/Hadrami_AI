"""Retrieval-grounded prompt templates.

All prompts here enforce the "lexicon-grounded" contract:
the model must not emit a dialectal mapping that is not licensed by an entry
in the retrieved context. See :doc:`docs/methods_evaluation` for the audit
that motivated these rewrites.
"""

from __future__ import annotations

import re
from typing import Any

from ..core.config import PHRASE_CONVERT_LONG_HINT_CHARS
from .text_utils import first_example, synonyms_from_entry


_USAGE_EXAMPLE_PATTERN = re.compile(r"\)\s*:\s*([^()]+?)\s*\(", re.UNICODE)


# Matches how users actually phrase a conversion request ("ترجم", "translate",
# "حول إلى الفصحى", ...) -- this is user-facing vocabulary we detect, not
# terminology the app itself uses to describe the feature.
_CONVERSION_INTENT_PATTERN = re.compile(
    r"(ترجم|ترجمة|إلى\s*الفصحى|إلى\s*العربية|بالفصحى|بالعربية\s*الفصحى|"
    r"translate|حول\s*إلى\s*الفصحى|عبر\s*إلى\s*الفصحى|فصحى\s*هذه)",
    re.IGNORECASE,
)


def looks_like_conversion_request(question: str) -> bool:
    q = (question or "").strip()
    return bool(q) and bool(_CONVERSION_INTENT_PATTERN.search(q))


# ---------------------------------------------------------------------------
# Shared context-block builders
# ---------------------------------------------------------------------------

def ask_context_block(entries: list[dict], definition_max_chars: int = 160) -> str:
    """Verbose context block used by ``/ask`` and ``/chat`` prompts.

    The block is wrapped with ``[CONTEXT START]`` / ``[CONTEXT END]`` markers
    that the unified system prompt looks for. When ``entries`` is empty the
    markers still render so the model knows retrieval ran but produced
    nothing.
    """
    blocks: list[str] = []
    cap = max(80, definition_max_chars)
    for entry in entries[:5]:
        head = str(entry.get("word_vocalized") or "").strip()
        fusha = str(entry.get("fusha_equivalent") or "").strip()
        definition = str(entry.get("definition") or "").strip()
        synonyms = synonyms_from_entry(entry)[:4]
        ex_h, ex_f = first_example(entry)
        eid = entry.get("id")

        lines = [f"- الكلمة الحضرمية: {head or 'غير متوفر'}"]
        if eid is not None:
            lines.append(f"  id: {eid}")
        if synonyms:
            lines.append(f"  المرادفات: {', '.join(synonyms)}")
        if fusha:
            lines.append(f"  المقابل الفصيح: {fusha}")
        if definition:
            lines.append(f"  الشرح القاموسي: {definition[:cap]}")
        if ex_h and ex_f:
            lines.append(f"  مثال قاموسي: {ex_h}")
            lines.append(f"  معنى المثال: {ex_f}")
        blocks.append("\n".join(lines))
    body = "\n\n".join(blocks) if blocks else "(لا توجد مطابقات قاموسية)"
    return f"[CONTEXT START]\n{body}\n[CONTEXT END]"


def phrase_context_block(entries: list[dict], *, definition_cap: int) -> str:
    """Compact one-entry-per-line block used by the phrase converter.

    Wrapped in ``[CONTEXT START]`` / ``[CONTEXT END]`` markers to match the
    unified system prompt's retrieval contract.
    """
    lines: list[str] = []
    for e in entries:
        syns = e.get("synonyms") or []
        syn_txt = (
            f" | مرادفات: {', '.join(syns[:4])}"
            if isinstance(syns, list) and syns
            else ""
        )
        lines.append(
            f"- حضرمي: {e.get('word_vocalized', '')} | فصحى: {e.get('fusha_equivalent', '')}"
            f"{syn_txt} | شرح: {(e.get('definition') or '')[:definition_cap]}"
        )
    body = "\n".join(lines) if lines else "(لم يُسترجَع أي مدخل قاموسي لهذا النص.)"
    return f"[CONTEXT START]\n{body}\n[CONTEXT END]"


# ---------------------------------------------------------------------------
# /ask prompts
# ---------------------------------------------------------------------------

def rag_prompt(question: str, context_entries: list[dict]) -> str:
    """Prompt used when the question is an informational query ("ما معنى …")."""
    context = ask_context_block(context_entries)
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
أدناه مراجع **مسترجَعة من قاعدة بيانات القاموس** ثم تُعطى لك للإجابة (RAG)؛ لا تخمّن من معرفة عامة خارجهما.
التزم حصراً بمحتواها. لا تذكر معانٍ أو أشكالاً حضرمية أو فصحى لم ترد فيها صراحة.
إذا لم تغطِ المراجعُ السؤال، فقل ذلك في جملة واحدة ولا تكمل بمعرفة عامة أو تخمين.
إذا ذكرت كلمة حضرمية من المراجع، فاكتبها حرفياً كما في «الكلمة الحضرمية» أو «المرادفات».
اجعل الإجابة موجزة بهذا الشكل:
- ابدأ باسم الكلمة الحضرمية بين علامتي تنسيق غامق.
- سطر «المعنى: ...» من المقابل الفصيح من المراجع فقط.
- سطر «الشرح: ...» جملة أو جملتان تلخصان الشرح القاموسي دون إضافة معلومات من خارج المراجع.
- سطر «مثال: ...» فقط إذا وُجد في المراجع مثال حضرمي+فصيح؛ وإلا اكتب «لا يوجد في المراجع مثال جاهز».
لا تكرر الشرح بصيغ متعددة، ولا تستخدم ألفاظاً عامة إذا كان للقاموس مقابل أدق.

{context}

السؤال: {question}

الإجابة:"""


def rag_prompt_no_hits(question: str) -> str:
    """Safety template: when retrieval is empty we normally skip the LLM entirely."""
    return f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
لم يُسترجَع أي مدخل قاموسي يدعم إجابةً موثوقة عن السؤال.
يجب أن ترد بجملة واحدة فقط تطلب من المستخدم إعادة الصياغة أو البحث في القاموس، دون ذكر معانٍ أو ترجمات من عندك.

السؤال: {question}

الإجابة:"""


def prompt_for_gemini(question: str, context_entries: list[dict]) -> str:
    return rag_prompt(question, context_entries) if context_entries else rag_prompt_no_hits(question)


# ---------------------------------------------------------------------------
# /ask — Hadrami→MSA conversion sub-prompt
# ---------------------------------------------------------------------------

def _few_shot_pairs_from_entry(entry: dict[str, Any]) -> list[tuple[str, str]]:
    hadrami_head = (entry.get("word_vocalized") or "").strip()
    fus_gloss = (entry.get("fusha_equivalent") or "").strip()
    definition = (entry.get("definition") or "").strip()
    out: list[tuple[str, str]] = []

    raw_examples = entry.get("examples")
    if isinstance(raw_examples, list):
        for ex in raw_examples[:4]:
            if not isinstance(ex, dict):
                continue
            h = (ex.get("h") or "").strip()
            f = (ex.get("f") or "").strip()
            if h and f:
                out.append((h, f))

    for m in _USAGE_EXAMPLE_PATTERN.finditer(definition):
        snippet = (m.group(1) or "").strip()
        if len(snippet) >= 3:
            gloss = fus_gloss if fus_gloss else definition[:160]
            out.append((snippet, gloss))

    if not out and hadrami_head and fus_gloss:
        out.append((hadrami_head, fus_gloss))

    return out[:2]


def conversion_prompt(question: str, context_entries: list[dict]) -> str:
    """Hadrami→MSA conversion prompt: demand grounding in retrieved lexicon only."""
    blocks: list[str] = []
    for e in context_entries[:12]:
        for had, fusha in _few_shot_pairs_from_entry(e):
            if len(blocks) >= 16:
                break
            had_clean = had.replace("\n", " ").strip()
            fusha_clean = fusha.replace("\n", " ").strip()
            if not had_clean or not fusha_clean:
                continue
            blocks.append(
                f"- Hadrami Example: {had_clean}\n  - Fusha Rendering: {fusha_clean}"
            )
        if len(blocks) >= 16:
            break

    if blocks:
        reference_text = "\n\n".join(blocks)
        intro = (
            "You convert Hadrami Arabic dialect into Modern Standard Arabic (MSA). "
            "Every content word mapping MUST be licensed by the Hadrami↔MSA pairs below. "
            "Do not invent senses, synonyms, or free paraphrase beyond what these pairs support. "
            "If the sentence cannot be converted faithfully from these pairs alone, output exactly one line:\n"
            "لم يُسترجَع قاموسياً ما يكفي لتحويل هذه الجملة بدقة."
        )
    else:
        reference_text = ask_context_block(context_entries, definition_max_chars=220)
        intro = (
            "You convert Hadrami Arabic dialect into Modern Standard Arabic (MSA). "
            "You MUST ground the conversion ONLY in the Arabic lexicon excerpt below "
            "(headwords, MSA glosses, definitions, examples). "
            "Do not use general bilingual knowledge to fill gaps. "
            "If the excerpt does not license a faithful full-sentence conversion, output exactly:\n"
            "لم يُسترجَع قاموسياً ما يكفي لتحويل هذه الجملة بدقة.\n"
            "Otherwise output only the MSA rendering."
        )

    return f"""{intro}

{reference_text}

Convert the following Hadrami text into Modern Standard Arabic. Output only the MSA rendering, or the exact refusal sentence above:
{question}"""


# ---------------------------------------------------------------------------
# /chat prompt
# ---------------------------------------------------------------------------

def chat_prompt(
    user_message: str,
    history: list[dict[str, str]],
    context_entries: list[dict],
) -> str:
    """User-message body for ``/chat``.

    System-level rules are in :mod:`.system_prompt`. This builder only
    supplies the retrieved context, recent conversation history, and the
    current user message.
    """
    context = ask_context_block(context_entries, definition_max_chars=320)
    history_block = ""
    if history:
        turns: list[str] = []
        for msg in history[-10:]:
            role = msg.get("role", "user")
            content = msg.get("content", "")
            label = "المستخدم" if role == "user" else "المساعد"
            turns.append(f"{label}: {content}")
        history_block = "\n".join(turns)

    history_section = (
        f"\nسجل المحادثة (للسياق؛ ركّز على آخر سؤال):\n{history_block}\n"
        if history_block
        else ""
    )

    return f"""{context}
{history_section}
المستخدم: {user_message}

المساعد:"""


# ---------------------------------------------------------------------------
# /convert-phrase prompt
# ---------------------------------------------------------------------------

def phrase_prompt(text: str, direction: str, entries: list[dict]) -> str:
    """Strict lexicon-grounded phrase conversion prompt."""
    n = len(text)
    def_cap = 70 if n > PHRASE_CONVERT_LONG_HINT_CHARS else 160
    ctx = phrase_context_block(entries, definition_cap=def_cap)
    long_note = ""
    if n > PHRASE_CONVERT_LONG_HINT_CHARS:
        long_note = (
            "\n\nالنص طويل: حافظ على ترتيب الجمل والفقرات دون حذف. "
            "في hadrami_spans أدرج على الأكثر 12 إدخالاً، وأدرج فقط أشكالاً "
            "تطابق مداخل وردت حرفياً في قائمة القاموس أعلاه."
        )
    if direction == "ar_to_hadrami":
        task = (
            "حوّل النص من العربية الفصحى إلى اللهجة الحضرمية. "
            "كل كلمة لهجية في ناتجك يجب أن تكون مذكورة في قائمة القاموس "
            "أعلاه (كمدخل أو مرادف أو ظاهرة في مثال). "
            "حروف الجر والضمائر والأدوات المشتركة مع الفصحى مسموحة دون قيد."
        )
        span_hint = (
            "في hadrami_spans ضع فقط كلمات حضرمية (من عمود حضرمي أو مرادفاته) "
            "وردت في قائمة القاموس أعلاه."
        )
    else:
        task = (
            "حوّل النص من اللهجة الحضرمية إلى العربية الفصحى. "
            "كل كلمة فصحى تقابل لفظاً لهجياً في النص يجب أن تُستمد من "
            "عمود «فصحى» أو من شرح مدخل قاموسي ورد في القائمة أعلاه. "
            "لا تعتمد على معرفتك العامة بمعاني الألفاظ الحضرمية."
        )
        span_hint = (
            "في hadrami_spans ضع فقط معادلات فصحى وردت في عمود «فصحى» "
            "في قائمة القاموس أعلاه."
        )

    empty_rule = (
        "\nإن لم تتضمن قائمة القاموس أي مدخل ذي صلة بالنص، "
        "أعد converted_text كسلسلة فارغة وأضف حقل note بالقيمة "
        '"insufficient_lexicon_coverage" وhadrami_spans فارغة.'
        if not entries
        else ""
    )

    return f"""أنت مُحوِّل لهجات بحثي مقيَّد بقاموس حضرمي-فصحى.
التزم حرفياً بالمداخل المسترجعة؛ لا تستنتج معاني لهجية من معرفتك العامة.

مراجع من القاموس (هذه هي المرجعية الوحيدة للمقابلات اللهجية):
{ctx}

المهمة: {task}
{span_hint}{long_note}{empty_rule}

النص الأصلي:
{text}

أعد الإجابة كـ JSON صالح فقط بدون شرح أو markdown:
{{"converted_text":"...","hadrami_spans":[{{"start":0,"end":3,"surface":"..."}}],"note":""}}

قواعد تقنية:
- start و end: موضعا الأحرف في converted_text (عدّ الأحرف كوحدات يونيكود، len والقطع كما في بايثون).
- surface يجب أن يساوي converted_text[start:end].
- hadrami_spans = [] إذا لم توجد مداخل قاموس مناسبة."""
    