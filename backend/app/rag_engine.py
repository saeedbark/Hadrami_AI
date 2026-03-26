import os
from typing import Optional

from .core.data_store import ENTRIES
from .services.dictionary_service import search as keyword_search

MODE = os.getenv("RAG_MODE", "local")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
# Default to a small model so local setup is fast; override via OLLAMA_MODEL.
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "tinyllama")


def _keyword_context(query: str, top_k: int = 5) -> list[dict]:
    result = keyword_search(query, limit=top_k)
    return result["results"]


class LocalRAG:
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
            return None

    def build_index(self) -> bool:
        collection = self._get_collection()
        if collection is None:
            return False

        if collection.count() >= len(ENTRIES):
            return True

        batch_size = 100
        for i in range(0, len(ENTRIES), batch_size):
            batch = ENTRIES[i : i + batch_size]
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

        return True

    def vector_search(self, query: str, top_k: int = 5) -> list[dict]:
        collection = self._get_collection()
        if collection is None or collection.count() == 0:
            return _keyword_context(query, top_k)

        results = collection.query(query_texts=[query], n_results=top_k)

        found = []
        for meta in results["metadatas"][0] if results["metadatas"] else []:
            word_id = meta.get("word_id")
            entry = next((e for e in ENTRIES if e["id"] == word_id), None)
            if entry:
                found.append(entry)
        return found

    def query_with_ollama(self, question: str) -> str:
        context_entries = self.vector_search(question, top_k=3)
        if not context_entries:
            return "لم أجد معلومات كافية."

        context = "\n".join(
            [
                f"- الكلمة: {e['hadrami_word']} | الفصحى: {e.get('arabic_fus7a', '')} | الشرح: {e.get('full_definition', '')[:100]}"
                for e in context_entries
            ]
        )

        prompt = f"""أنت مساعد متخصص في اللهجة الحضرمية اليمنية.
استخدم المعلومات التالية فقط للإجابة:

{context}

السؤال: {question}

الإجابة:"""

        try:
            import requests

            resp = requests.post(
                f"{OLLAMA_URL}/api/generate",
                json={"model": OLLAMA_MODEL, "prompt": prompt, "stream": False},
                timeout=30,
            )
            if resp.status_code == 200:
                return resp.json().get("response", "").strip()
        except Exception as e:
            return f"Ollama not available: {e}"

        return context_entries[0].get("arabic_fus7a", "")


class ProdRAG:
    def __init__(self, gemini_key: Optional[str] = None):
        self.gemini_key = gemini_key or os.getenv("GEMINI_API_KEY", "")

    def query(self, question: str) -> str:
        try:
            import google.generativeai as genai

            genai.configure(api_key=self.gemini_key)

            context_entries = _keyword_context(question, top_k=3)
            context = "\n".join(
                [
                    f"- {e['hadrami_word']}: {e.get('arabic_fus7a', '')} — {e.get('full_definition', '')[:150]}"
                    for e in context_entries
                ]
            )

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


_local_rag = None
_prod_rag = None


def get_rag_answer(question: str) -> dict:
    global _local_rag, _prod_rag

    context = _keyword_context(question, top_k=3)

    if MODE == "simple" or not context:
        answer = context[0].get("arabic_fus7a", "غير موجود") if context else "غير موجود"
        return {"answer": answer, "context": context, "mode": "simple"}

    elif MODE == "local":
        if _local_rag is None:
            _local_rag = LocalRAG()
        answer = _local_rag.query_with_ollama(question)
        if answer.startswith("Ollama not available:"):
            answer = context[0].get("arabic_fus7a", "غير موجود") if context else "غير موجود"
            return {"answer": answer, "context": context, "mode": "simple"}
        return {"answer": answer, "context": context, "mode": "local_ollama"}

    elif MODE == "prod":
        if _prod_rag is None:
            _prod_rag = ProdRAG()
        answer = _prod_rag.query(question)
        return {"answer": answer, "context": context, "mode": "gemini"}

    answer = context[0].get("arabic_fus7a", "غير موجود") if context else "غير موجود"
    return {"answer": answer, "context": context, "mode": "fallback"}


if __name__ == "__main__":
    import sys

    query = sys.argv[1] if len(sys.argv) > 1 else "ما معنى كلمة ويش؟"
    print(f"Query: {query}")
    print(f"Mode: {MODE}")
    result = get_rag_answer(query)
    print(f"Answer: {result['answer']}")
    print(f"Context ({len(result['context'])} entries):")
    for e in result["context"]:
        print(f"  - {e['hadrami_word']} -> {e.get('arabic_fus7a', '')}")
