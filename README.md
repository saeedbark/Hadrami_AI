# 🗺️ قاموس اللهجة الحضرمية - Hadrami NLP Project

مشروع NLP كامل للهجة الحضرمية: Backend FastAPI + Frontend Flutter

--

## 📁 هيكل المشروع

```
hadrami_project/
├── backend/
│   ├── app/
│   │   └── main.py          ← FastAPI server (كل الـ API)
│   ├── data/
│   │   ├── hadrami_dataset.json   ← 954 كلمة حضرمية
│   │   └── feedback.json    ← ملاحظات المستخدمين (يُنشأ تلقائياً)
│   ├── requirements.txt
│   └── run.sh               ← سكريبت التشغيل
│
└── flutter_app/
    ├── lib/
    │   ├── main.dart         ← Entry point + Navigation
    │   ├── models/
    │   │   └── word_entry.dart    ← Data models
    │   ├── services/
    │   │   ├── api_service.dart   ← HTTP calls to backend
    │   │   └── app_provider.dart  ← State management (Provider)
    │   ├── screens/
    │   │   ├── home_screen.dart       ← الرئيسية + ترجمة
    │   │   ├── search_screen.dart     ← البحث
    │   │   ├── dictionary_screen.dart ← القاموس الكامل
    │   │   └── favorites_screen.dart  ← المفضلة
    │   └── widgets/
    │       ├── word_card.dart             ← بطاقة الكلمة
    │       ├── word_detail_sheet.dart     ← تفاصيل الكلمة
    │       └── translate_result_card.dart ← نتيجة الترجمة
    └── pubspec.yaml
```

---

## 🚀 التشغيل

### 1. Backend (FastAPI)

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

**أو شغّل:**
```bash
chmod +x run.sh && ./run.sh
```

**الـ API يعمل على:** http://localhost:8000
**الـ Docs على:** http://localhost:8000/docs

---

### 2. Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

> **ملاحظة:** للتشغيل على جهاز حقيقي، غيّر `baseUrl` في `api_service.dart`:
> ```dart
> static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';
> ```

---

## 🔌 API Endpoints

| Method | Endpoint | الوصف |
|--------|----------|-------|
| GET | `/` | معلومات الـ API |
| GET | `/stats` | إحصائيات القاموس |
| GET | `/translate?q=كلمة` | ترجمة كلمة حضرمية |
| GET | `/search?q=كلمة` | بحث في القاموس |
| GET | `/words?page=1&size=20` | قائمة الكلمات |
| GET | `/word/{id}` | كلمة محددة |
| GET | `/random` | كلمة عشوائية |
| POST | `/feedback` | إرسال تصحيح |

---

## 📊 Dataset

- **954 كلمة** حضرمية مستخرجة من القاموس الحضرمي
- كل كلمة تحتوي على: الكلمة الحضرمية، الفصحى، الشرح الكامل
- الملف: `backend/data/hadrami_dataset.json`

---

## 🏗️ المرحلة القادمة (RAG + AI)

لإضافة الذكاء الاصطناعي:

```bash
# Local (مجاني)
pip install chromadb sentence-transformers ollama

# Production
pip install google-generativeai firebase-admin
```

ثم أضف في `main.py`:
```python
from chromadb import Client
# Vector search + Gemini embeddings
```

---

## 📱 شاشات التطبيق

1. **الرئيسية** - ترجمة سريعة + إحصائيات + كلمة اليوم
2. **البحث** - بحث فوري أثناء الكتابة
3. **القاموس** - كل الكلمات + فلتر بالحروف
4. **المفضلة** - الكلمات المحفوظة

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | FastAPI + Python |
| Frontend | Flutter + Provider |
| Database | JSON → Firebase (مرحلة الإنتاج) |
| AI (مستقبل) | Gemini + ChromaDB RAG |

---

*بُني لمؤتمر ذكاء اصطناعي - سعيد 2025*
