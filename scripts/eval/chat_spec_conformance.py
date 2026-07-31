"""Manual-spec conformance probe for POST /chat.

Runs the 12 examples from the project spec against the deployed backend and
records intent + reply so they can be scored by hand.
"""

from __future__ import annotations

import json
import sys
import time
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "https://hadrami-ai.vercel.app"

CASES = [
    ("1  word→interpret",   "إبط",                     "word",     "التريث / عدم الاستعجال"),
    ("2  word→interpret",   "أم حبيل",                 "word",     "العنكبوت"),
    ("3  sent→convert",     "أبوي راح السوق الصبح",     "convert",  "ذهب والدي إلى السوق صباحاً"),
    ("4  sent→convert",     "ادحق بسرعة لا نتأخر",      "convert",  "امشِ/أسرع كي لا نتأخر"),
    ("5  para→convert",     "أبوي قال لي إبط في شغلك، لا تستعجل. أنا ما سمعت كلامه وادحقت بسرعة، وبعدها أثّر علي الغلط. أثره كان هو الصح.",
                                                        "convert",  "paragraph stays connected, no word-by-word"),
    ("6  semantic",         "كلمة تعني التريث وعدم الاستعجال", "semantic", "إبط"),
    ("7  semantic",         "كلمة تستخدم للأطفال لطلب الماء",  "semantic", "أمبوه"),
    ("8  mixed para",       "اليوم شفت أم حبيل في السقف، قلت لاخوي إكس عليه وخله، لكنه أكشف وخاف منها.",
                                                        "convert",  "عنكبوت + تجاهله + عنيد"),
    ("9  question",         "متى تستخدم كلمة أثره؟",     "qa",       "اتضح أن / خلاف المتوقع"),
    ("10 phrase convert",   "إبط في شغلك تسرع في الإنجاز", "convert", "تأنَّ في عملك"),
    ("11 word→interpret",   "بخت",                      "word",     "الحظ / النصيب"),
    ("12 unknown word",     'سمعت كلمة "زنكوش" وما فهمتها', "convert", "must say NOT FOUND, not invent"),
]


def call(msg: str) -> dict:
    body = json.dumps({"message": msg, "history": []}).encode()
    req = urllib.request.Request(
        f"{BASE}/chat", data=body, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.loads(r.read().decode())


def main() -> None:
    out = []
    for label, msg, want_intent, want_gist in CASES:
        t0 = time.time()
        try:
            data = call(msg)
            err = None
        except Exception as exc:  # noqa: BLE001
            data, err = {}, repr(exc)
        dt = time.time() - t0
        rec = {
            "case": label,
            "input": msg,
            "expected_intent": want_intent,
            "got_intent": data.get("intent"),
            "expected_gist": want_gist,
            "reply": (data.get("reply") or "").strip(),
            "answer_source": data.get("answer_source"),
            "suggest_word": data.get("suggest_word"),
            "n_context": len(data.get("context") or []),
            "secs": round(dt, 1),
            "error": err,
        }
        out.append(rec)
        flag = "OK " if rec["got_intent"] == want_intent else "!! "
        print(f"{flag}{label:22} intent={rec['got_intent']!s:9} "
              f"src={rec['answer_source']!s:8} ctx={rec['n_context']:2} {rec['secs']:5}s")
        if err:
            print(f"     ERROR {err}")
    with open("chat_eval_results.json", "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("\nwrote chat_eval_results.json")


if __name__ == "__main__":
    main()
