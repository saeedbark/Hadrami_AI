"""Unit tests for sanitize_model_reply -- the defense-in-depth strip of
prompt-scaffold artifacts (raw ids, echoed context blocks/role labels) that
occasionally leak into a Gemini reply. See docs/chat_testing.md."""

from __future__ import annotations

from app.rag.text_utils import sanitize_model_reply


def test_sanitize_model_reply_strips_leaked_id_line() -> None:
    leaked = "📖 إبِطْ\n- المعنى: التأني وعدم الاستعجال\n  id: 50\n- الفصحى: التباطؤ"
    cleaned = sanitize_model_reply(leaked)
    assert "id: 50" not in cleaned
    assert "إبِطْ" in cleaned
    assert "التباطؤ" in cleaned


def test_sanitize_model_reply_strips_leaked_context_block() -> None:
    leaked = (
        "[CONTEXT START]\n- الكلمة الحضرمية: إبط\n  id: 12\n[CONTEXT END]\n"
        "المساعد: إبِطْ تعني التأني."
    )
    cleaned = sanitize_model_reply(leaked)
    assert "[CONTEXT START]" not in cleaned
    assert "[CONTEXT END]" not in cleaned
    assert "id: 12" not in cleaned
    assert "إبِطْ تعني التأني." in cleaned


def test_sanitize_model_reply_strips_leaked_role_prefix() -> None:
    leaked = "المساعد: تأنَّ في عملك تنجزه أسرع."
    cleaned = sanitize_model_reply(leaked)
    assert cleaned == "تأنَّ في عملك تنجزه أسرع."


def test_sanitize_model_reply_leaves_clean_text_unchanged() -> None:
    clean = "📖 بخت\n- المعنى: الحظ / النصيب\n- الفصحى: الحظ"
    assert sanitize_model_reply(clean) == clean


def test_sanitize_model_reply_handles_empty_string() -> None:
    assert sanitize_model_reply("") == ""
