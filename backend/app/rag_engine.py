"""
RAG Engine for Hadrami NLP
==========================
Two modes:
  - LOCAL  : Ollama (aya:8b) + ChromaDB  — free, runs on your machine
  - PROD   : Gemini 1.5 Flash + Firebase  — paid, for deployment

Switch by setting RAG_MODE env var or changing MODE below.
"""

import os
import json
from pathlib import Path
from typing import List, Optional

MODE = os.getenv("RAG_MODE", "simple")  # "simple" | "local" | "prod" — simple works without Ollama

DATA_FILE = Path(__file__).parent.parent / "data" / "hadrami_dataset.json"

# ── Load dataset ────────────────────────────────────────────────────────────
def _load_entries():
    if DATA_FILE.exists():
        with open(DATA_FILE, encoding="utf-8") as f:
            return json.load(f)["entries"]
    return []

ENTRIES = _load_entries()

# ══════════════════════════════════════════════════════════════════════════════
# SIMPLE MODE — keyword matching, no AI needed, works right now
# ══════════════════════════════════════════════════════════════════════════════
def simple_search(query: str, top_k: int = 5) -> List[dict]:
    """Fast keyword search without any AI"""
    q = query.strip()
    scored = []
    for e in ENTRIES:
        score = 0
        if e["hadrami_word"].strip() == q:
            score = 100
        elif q in e["hadrami_word"]:
            score = 80
        elif e["hadrami_word"] in q:
            score = 70
        elif q in e.get("arabic_fus7a", ""):
            score = 60
        elif q in e.get("full_definition", ""):
            score = 40
        if score > 0:
            scored.append((score, e))
    scored.sort(key=lambda x: -x[0])
    return [r[1] for r in scored[:top_k]]


# ══════════════════════════════════════════════════════════════════════════════
# LOCAL MODE — Ollama + ChromaDB (FREE)
# Install: pip install chromadb sentence-transformers
#          ollama pull aya:8b
# ══════════════════════════════════════════════════════════════════════════════
class LocalRAG:
    """
    Local RAG using ChromaDB for vector search + Ollama for generation.
    
    Usage:
        rag = LocalRAG()
        rag.build_index()          # Run once to create the index
        result = rag.query("ويش") # Query the RAG
    """
    
    def __init__(self):
        self._collection = None
        self._client = None
    
    def _get_collection(self):
        if self._collection is not None:
            return self._collection
        try:
            import chromadb
            from chromadb.utils import embedding_functions
            
            self._client = chromadb.PersistentClient(path="./hadrami_chroma_db")
            
            emb_fn = embedding_functions.SentenceTransformerEmbeddingFunction(
                model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            )
            
            self._collection = self._client.get_or_create_collection(
                name="hadrami_words",
                embedding_function=emb_fn,
                metadata={"hnsw:space": "cosine"},
            )
            return self._collection
        except ImportError:
            print("⚠️  ChromaDB not installed. Run: pip install chromadb sentence-transformers")
            return None
    
    def build_index(self):
        """Index all words. Run once, then the DB persists."""
        collection = self._get_collection()
        if collection is None:
            return False
        
        if collection.count() >= len(ENTRIES):
            print(f"✅ Index already built ({collection.count()} entries)")
            return True
        
        print(f"🔨 Building index for {len(ENTRIES)} entries...")
        
        # Batch insert
        batch_size = 100
        for i in range(0, len(ENTRIES), batch_size):
            batch = ENTRIES[i:i + batch_size]
            ids = [str(e["id"]) for e in batch]
            docs = [
                f"{e['hadrami_word']} {e.get('arabic_fus7a', '')} {e.get('full_definition', '')}"
                for e in batch
            ]
            metas = [
                {
                    "hadrami_word": e["hadrami_word"],
                    "arabic_fus7a": e.get("arabic_fus7a", ""),
                    "word_id": e["id"],
                }
                for e in batch
            ]
            collection.upsert(ids=ids, documents=docs, metadatas=metas)
            print(f"  Indexed {min(i + batch_size, len(ENTRIES))}/{len(ENTRIES)}")
        
        print("✅ Index built!")
        return True
    
    def vector_search(self, query: str, top_k: int = 5) -> List[dict]:
        """Search using vector similarity"""
        collection = self._get_collection()
        if collection is None or collection.count() == 0:
            return simple_search(query, top_k)
        
        results = collection.query(
            query_texts=[query],
            n_results=top_k,
        )
        
        # Find full entries
        found = []
        for meta in (results["metadatas"][0] if results["metadatas"] else []):
            word_id = meta.get("word_id")
            entry = next((e for e in ENTRIES if e["id"] == word_id), None)
            if entry:
                found.append(entry)
        return found
    
    def query_with_ollama(self, question: str) -> str:
        """Generate natural language answer using Ollama"""
        # Get context from vector search
        context_entries = self.vector_search(question, top_k=3)
        
        if not context_entries:
            return "لم أجد معلومات كافية."
        
        context = "\n".join([
            f"- الكلمة: {e['hadrami_word']} | الفصحى: {e.get('arabic_fus7a', '')} | الشرح: {e.get('full_definition', '')[:100]}"
            for e in context_entries
        ])
        
        prompt = f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
استخدم المعلومات التالية فقط للإجابة:

{context}

السؤال: {question}

الإجابة:"""
        
        try:
            import requests
            resp = requests.post(
                "http://localhost:11434/api/generate",
                json={"model": "aya:8b", "prompt": prompt, "stream": False},
                timeout=30
            )
            if resp.status_code == 200:
                return resp.json().get("response", "").strip()
        except Exception as e:
            return f"Ollama not available: {e}"
        
        return context_entries[0].get("arabic_fus7a", "")


# ══════════════════════════════════════════════════════════════════════════════
# PROD MODE — Gemini + Firebase (for deployment)
# Install: pip install google-generativeai firebase-admin
# ══════════════════════════════════════════════════════════════════════════════
class ProdRAG:
    """
    Production RAG using Google Gemini embeddings + Firebase Vector Search.
    
    Usage:
        rag = ProdRAG(gemini_key="YOUR_KEY")
        result = rag.query("ويش معناها؟")
    """
    
    def __init__(self, gemini_key: Optional[str] = None):
        self.gemini_key = gemini_key or os.getenv("GEMINI_API_KEY", "")
    
    def query(self, question: str) -> str:
        """Full RAG pipeline: embed → search → generate"""
        try:
            import google.generativeai as genai
            genai.configure(api_key=self.gemini_key)
            
            # 1. Get context (simple search for now, replace with Firebase vector search)
            context_entries = simple_search(question, top_k=3)
            
            context = "\n".join([
                f"- {e['hadrami_word']}: {e.get('arabic_fus7a', '')} — {e.get('full_definition', '')[:150]}"
                for e in context_entries
            ])
            
            # 2. Generate with Gemini
            model = genai.GenerativeModel("gemini-1.5-flash")
            prompt = f"""أنت مساعد في اللهجة الحضرمية اليمنية.

السياق من القاموس الحضرمي:
{context}

السؤال: {question}

أجب بالعربية الفصحى بشكل موجز ومفيد:"""
            
            response = model.generate_content(prompt)
            return response.text.strip()
        
        except ImportError:
            return "google-generativeai not installed"
        except Exception as e:
            return f"Error: {e}"


# ══════════════════════════════════════════════════════════════════════════════
# Factory function — use this in main.py
# ══════════════════════════════════════════════════════════════════════════════
_local_rag = None
_prod_rag = None

def get_rag_answer(question: str) -> dict:
    """
    Main entry point for RAG queries.
    Returns: {"answer": str, "context": list, "mode": str}
    """
    global _local_rag, _prod_rag
    
    # Always get keyword context
    context = simple_search(question, top_k=3)
    
    if MODE == "simple" or not context:
        answer = context[0].get("arabic_fus7a", "غير موجود") if context else "غير موجود"
        return {"answer": answer, "context": context, "mode": "simple"}
    
    elif MODE == "local":
        if _local_rag is None:
            _local_rag = LocalRAG()
        answer = _local_rag.query_with_ollama(question)
        # If Ollama is not running, fall back to dictionary answer instead of showing error
        if answer.startswith("Ollama not available:"):
            answer = context[0].get("arabic_fus7a", "غير موجود") if context else "غير موجود"
            return {"answer": answer, "context": context, "mode": "simple"}
        return {"answer": answer, "context": context, "mode": "local_ollama"}
    
    elif MODE == "prod":
        if _prod_rag is None:
            _prod_rag = ProdRAG()
        answer = _prod_rag.query(question)
        return {"answer": answer, "context": context, "mode": "gemini"}
    
    # Default fallback
    answer = context[0].get("arabic_fus7a", "غير موجود") if context else "غير موجود"
    return {"answer": answer, "context": context, "mode": "fallback"}


# ── CLI test ─────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import sys
    query = sys.argv[1] if len(sys.argv) > 1 else "ما معنى كلمة ويش؟"
    print(f"Query: {query}")
    print(f"Mode: {MODE}")
    result = get_rag_answer(query)
    print(f"Answer: {result['answer']}")
    print(f"Context ({len(result['context'])} entries):")
    for e in result['context']:
        print(f"  - {e['hadrami_word']} → {e.get('arabic_fus7a', '')}")
