"""
One-off: Enrich Hadrami JSON with Gemini (Batch Processing Mode).
Updated for better API stability.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

import google.generativeai as genai
from tqdm import tqdm

# Must match backend/app/rag_engine.py — old alias "gemini-1.5-flash" often 404s.
_DEFAULT_GEMINI = "gemini-2.5-flash"
_GEMINI_FALLBACKS = [
    "gemini-2.0-flash",
    "gemini-2.5-flash-lite",
    "gemini-1.5-flash-002",
]


def _gemini_model_order() -> list[str]:
    primary = (os.getenv("GEMINI_MODEL") or _DEFAULT_GEMINI).strip()
    out: list[str] = []
    for m in [primary, *_GEMINI_FALLBACKS]:
        if m and m not in out:
            out.append(m)
    return out


def _generate_text(prompt: str) -> str:
    order = _gemini_model_order()
    last_err: Exception | None = None
    for mname in order:
        try:
            model = genai.GenerativeModel(mname)
            response = model.generate_content(prompt)
            text = (response.text or "").strip()
            if mname != order[0]:
                print(f"(استخدمت الموديل الاحتياطي: {mname})")
            return text
        except Exception as e:
            last_err = e
            print(f"⚠️ فشل الموديل {mname!r}: {e}")
    assert last_err is not None
    raise last_err


def augment_data_batch(
    input_file: str | Path,
    output_file: str | Path,
    batch_size: int = 10,
    sleep_seconds: float = 4.0,
) -> None:
    # 1. إعداد الـ API Key مباشرة
    api_key = (os.getenv("GEMINI_API_KEY") or "").strip()
    if not api_key:
        print("خطأ: يرجى التأكد من وجود GEMINI_API_KEY في ملف .env")
        sys.exit(1)

    genai.configure(api_key=api_key)

    input_path = Path(input_file)
    output_path = Path(output_file)

    with open(input_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # نظام استئناف متقدم
    if output_path.exists():
        with open(output_path, "r", encoding="utf-8") as f:
            enriched_data = json.load(f)
        processed_ids = {item.get("id") for item in enriched_data if item.get("is_augmented")}
        print(f"تم العثور على ملف سابق. تم معالجة {len(processed_ids)} كلمة مسبقاً.")
    else:
        enriched_data = data.copy()
        processed_ids = set()

    # إنشاء قائمة بالكلمات التي لم تعالج بعد
    pending_items = [item for item in enriched_data if item.get("id") not in processed_ids]
    
    # معالجة بالدفعات
    from itertools import islice
    def chunker(seq, size):
        it = iter(seq)
        return iter(lambda: list(islice(it, size)), [])

    for batch in tqdm(chunker(pending_items, batch_size), desc="Processing Batches"):
        
        # تجهيز البيانات للبرومبت
        batch_input = [{"id": item["id"], "w": item.get("word_vocalized"), "def": item.get("definition")} for item in batch]
        
        prompt = f"""
        أنت خبير لغوي. لديك قائمة كلمات حضرمية. لكل كلمة، قم بتوليد 5 أمثلة (جمل).
        الكلمات: {json.dumps(batch_input, ensure_ascii=False)}

        المطلوب: إرجاع JSON فقط عبارة عن قائمة (List) تحتوي على الكائنات التالية:
        {{"id": الرقم_المرسل, "examples": [ {{"h": "جملة حضرمية", "f": "ترجمة فصحى"}}, ... ]}}
        
        لا تكتب أي نص إضافي، فقط JSON.
        """

        try:
            raw = _generate_text(prompt)
            clean_text = raw.replace("```json", "").replace("```", "").strip()
            results = json.loads(clean_text)

            # دمج النتائج
            for result in results:
                for item in enriched_data:
                    if item["id"] == result["id"]:
                        item["examples"] = result["examples"]
                        item["is_augmented"] = True
                        break
            
            # حفظ تلقائي
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(enriched_data, f, ensure_ascii=False, indent=2)

        except Exception as e:
            print(f"\n[خطأ تقني] {e}. سأنتظر 60 ثانية وأحاول مجدداً...")
            time.sleep(60)
            continue

        time.sleep(sleep_seconds)

def main() -> None:
    # تحميل البيئة
    from dotenv import load_dotenv
    _ROOT = Path(__file__).resolve().parent
    load_dotenv(_ROOT / "backend" / ".env")

    p = argparse.ArgumentParser()
    p.add_argument("input", nargs="?", default="hadrami_clearn.json")
    p.add_argument("output", nargs="?", default="hadrami_enriched_v2.json")
    args = p.parse_args()
    
    augment_data_batch(args.input, args.output)

if __name__ == "__main__":
    main()