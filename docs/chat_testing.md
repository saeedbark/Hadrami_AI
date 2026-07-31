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

## 4. Known issues found on 2026-07-30

Measured, not assumed. Local = backend running with the `.env` Gemini key;
Prod = `https://hadrami-ai.vercel.app`.

| | Intent correct | Gemini reached |
|---|---|---|
| Local | 11 / 12 | yes |
| Prod | 8 / 12 | **0 / 12** |

1. **Production has no working Gemini.** Every one of the 12 cases returned
   `answer_source: lexicon`. Sentence and paragraph conversion are effectively
   dead in production — cases 3 and 5 return
   `تعذّر الاتصال بنموذج الإجابة`. Fix is a config change, not code: set
   `GEMINI_API_KEY` as a Production env var in the Vercel project `hadrami-ai`.

2. **Production is running older code than `main`.** `/stats` returns the key
   `translated` in production vs `completed` locally, and the intent label
   `translate` vs `convert`. Production predates the interpretation/conversion
   renaming.

3. **`phrase_top_score()` always returns 0.**
   `search_phrase_lexicon()` (dictionary_service.py:487) computes per-entry
   scores internally but returns only `{"total", "results"}` — never
   `top_score`. So `phrase_top_score()` reads a missing key and yields 0 for
   every input, including an exact single-word hit like `إبط`. Consequence:
   the keyword branch of `_is_confidently_grounded()` can never fire for
   convert intent, and `_lexicon_fallback_answer()` always refuses
   (`top_score < 70`).

4. **The phrase scorer ignores Arabic normalization.**
   `_score_phrase_token_match()` compares against raw `word_vocalized` only.
   It does not use the undiacritized `word_clean` column or `_normalize_alef()`
   — both of which the working `/search` scorer (`_entry_match_score`) *does*
   use. Measured effect:
   - `ادحق` vs its own entry `إِدْحَق / دَحَق` → score **0** (diacritics + `ا`/`إ`)
   - stopword `لا` vs `طُلاب` → score **88** (pure substring accident)

   So real content words score zero while stopwords score high. Fixing issue 3
   alone would make this worse, not better — it would ground answers on the
   spurious stopword matches. Both need fixing together.

5. **Intent classifier gap (case 7).** `_SEMANTIC_PATTERN` matches
   `كلمة تعني` and `كلمة ل` but not `كلمة تستخدم`, so
   `كلمة تستخدم للأطفال لطلب الماء` falls through to `convert`.

6. **Chat history is not persisted.** It lives in in-memory Riverpod state; a
   page reload clears the conversation.

### Impact on evaluation

Issues 3 and 4 mean phrase- and paragraph-level conversion is not really being
grounded by keyword retrieval at all — it currently succeeds only when vector
similarity happens to clear `RAG_CONFIDENCE_GATE`. Any Recall@k / grounding
numbers measured on the current code describe the vector path alone, so they
should not be reported as characterising the hybrid retriever.
