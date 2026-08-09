# Manual test protocol — `/chat`

How to check whether the unified chat endpoint is behaving correctly, and what
a correct result looks like for each intent.

Last run: 2026-07-30, against local backend (`.env` Gemini key) and the
deployed backend (`https://hadrami-ai.vercel.app`).

---

## 0. Before you test: know which backend you are hitting

Results differ *completely* between local and production, so always confirm
first. The single most useful signal is the `answer_source` field:

| `answer_source` | Meaning |
|---|---|
| `model` | Gemini answered — the real RAG path |
| `lexicon` | Gemini was unavailable; you are seeing the offline dictionary fallback |

If every reply comes back `lexicon`, **Gemini is not configured on that
backend** and you are not testing the real system. See "Known issues" below.

Run the backend locally:

```bash
cd backend && source venv/bin/activate && uvicorn app.main:app --port 8000 --reload
```

---

## 1. Fastest check — curl a single message

```bash
curl -s -X POST http://localhost:8000/chat -H 'Content-Type: application/json' -d '{"message":"إبط","history":[]}' | python3 -m json.tool
```

Look at three fields:
- `intent` — did the classifier route it correctly?
- `answer_source` — `model` or `lexicon`?
- `reply` — is the content right?

---

## 2. The 12-case conformance set

These are the spec examples. Send each as `message` with `history: []`.

| # | Input | Expected `intent` | Expected reply (gist) |
|---|---|---|---|
| 1 | `إبط` | `word` | التأني وعدم الاستعجال |
| 2 | `أم حبيل` | `word` | العنكبوت |
| 3 | `أبوي راح السوق الصبح` | `convert` | ذهب والدي إلى السوق في الصباح |
| 4 | `ادحق بسرعة لا نتأخر` | `convert` | امشِ/أسرع كي لا نتأخر |
| 5 | `أبوي قال لي إبط في شغلك، لا تستعجل...` (full paragraph) | `convert` | one connected MSA paragraph, **not** word-by-word |
| 6 | `كلمة تعني التريث وعدم الاستعجال` | `semantic` | proposes `إبط` |
| 7 | `كلمة تستخدم للأطفال لطلب الماء` | `semantic` | proposes `أمبوه` |
| 8 | `اليوم شفت أم حبيل في السقف...` | `convert` | عنكبوت + تجاهله + عنيد, connected |
| 9 | `متى تستخدم كلمة أثره؟` | `qa` | بمعنى "اتضح أن" / خلاف المتوقع |
| 10 | `إبط في شغلك تسرع في الإنجاز` | `convert` | تأنَّ في عملك |
| 11 | `بخت` | `word` | الحظ / النصيب |
| 12 | `سمعت كلمة "زنكوش" وما فهمتها` | `convert` | must say the word is **not in the lexicon** — must not invent a meaning |

### What a correct answer actually looks like

Verified real outputs from the local backend (Gemini enabled):

**Case 1 — `word`**
```
📖 إبِطْ
- المعنى: التأني وعدم الاستعجال في الأمر...
- الفصحى: التباطؤ والتريث
- نوع الكلمة: فعل
- مثال: إبط في شغلك تسرع في الإنجاز. ← تأنَّ في عملك تنجزه أسرع.
```

**Case 6 — `semantic`**
```
🔍 أقرب كلمة:
"إبِطْ" — التأني وعدم الاستعجال...
```

**Case 10 — `convert`** → `تأنَّ في عملك تنجزه أسرع (بجودة).`

**Case 9 — `qa`** → a grounded paragraph explaining أثره means "تبيّن/اتضح أن".

### Failure signatures to watch for

| Reply text | What it means |
|---|---|
| `_(إجابة مبسّطة من القاموس فقط؛ لتفسير أغنى فعّل نموذج Gemini.)_` | Gemini off — lexicon fallback |
| `تعذّر الاتصال بنموذج الإجابة` | Gemini call failed |
| `لم يُسترجَع قاموسياً ما يكفي لتحويل هذه الجملة بدقة` | retrieval gate rejected the input |
| `هذه الكلمة غير موجودة في القاموس الحالي` | suggest-word short-circuit fired |

The last two are **correct behaviour when the word is genuinely absent**, and a
**bug when the word is in the lexicon** — check with
`curl "http://localhost:8000/search?q=<word>"` before concluding.

---

## 3. Automated version

`scratchpad/chat_eval.py` in the session scratchpad runs all 12 and writes a
JSON report. Point it at either backend:

```bash
python3 chat_eval.py http://localhost:8000
```

---

## 4. Known issues found on 2026-07-30 — status as of 2026-08-08

Measured, not assumed. Local = backend running with the `.env` Gemini key;
Prod = `https://hadrami-ai.vercel.app`.

| | Intent correct | Gemini reached |
|---|---|---|
| Local (2026-07-30) | 11 / 12 | yes |
| Prod (2026-07-30) | 8 / 12 | **0 / 12** |

**Fixed 2026-08-08** (verified locally against the real Supabase+Gemini
backend — case 4 `ادحق بسرعة لا نتأخر` now returns the exact expected reply
`امشِ بسرعة كي لا نتأخر.` with `answer_source: "model"`; case 7
`كلمة تستخدم للأطفال لطلب الماء` now classifies as `semantic` and proposes
`أَمْبُوه`; case 12 `زنكوش` still correctly refuses instead of hallucinating):

3. ~~**`phrase_top_score()` always returns 0.**~~ Fixed:
   `search_phrase_lexicon()` (`dictionary_service.py`) now returns a
   `top_score` computed from its own ranked results, so `phrase_top_score()`
   no longer reads a missing key.

4. ~~**The phrase scorer ignores Arabic normalization.**~~ Fixed:
   `_score_phrase_token_match()` now compares the alef-normalized candidate
   against `word_clean` (mirroring `_entry_match_score()`), and the
   substring-match branch now requires `len(cand) >= 3`, closing the
   2-letter-stopword false-positive path (`لا` vs `طُلاب` now scores 0
   instead of 88).

5. ~~**Intent classifier gap (case 7).**~~ Fixed: `_SEMANTIC_PATTERN` now also
   matches `كلمة تستخدم`.

**New fix, not in the original list**: added `sanitize_model_reply()`
(`text_utils.py`) as a defense-in-depth strip of leaked prompt-scaffold
artifacts (raw `id: N` lines, echoed `[CONTEXT START]...[CONTEXT END]`
blocks, echoed `المساعد:`/`المستخدم:` role labels) from every Gemini reply
before it reaches the client, addressing the ~1-in-3 follow-up-turn prompt
leakage observed earlier.

**Still open — not code bugs, need a separate decision**:

1. **Production has no working Gemini / is running older code than `main`.**
   Config/deploy issue (`GEMINI_API_KEY` not set as a Vercel Production env
   var; production predates the interpretation/conversion renaming). Needs
   the user to confirm before touching the Vercel project.

2. **Chat history is not persisted.** Lives in in-memory Riverpod state; a
   page reload clears the conversation. Tracked as a feature request in
   `ROADMAP.md`, not a P0 bug.

3. **Supabase `apply_entry_embedding` is `SECURITY DEFINER` and
   anon-executable** over the public REST API — a separate security finding
   from the same audit, needs a migration decision from the user before any
   Supabase change is made.

### Impact on evaluation

The retrieval-grounding caveat from the original write-up (issues 3+4 meaning
Recall@k/grounding numbers only characterised the vector path) no longer
applies as of the 2026-08-08 fix — the keyword branch is live again. Any
evaluation numbers gathered *before* this date should still be treated with
that caveat; numbers gathered after should not carry it forward without
re-verifying.
