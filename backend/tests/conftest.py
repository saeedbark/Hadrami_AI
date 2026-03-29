import os
import sys
from pathlib import Path


def pytest_configure():
    # Ensure tests default to a deterministic, offline mode unless a test overrides it.
    os.environ.setdefault("RAG_MODE", "simple")
    os.environ.setdefault("RAG_DEBUG", "0")
    # Make sure `backend/` is on sys.path so `import app...` works reliably.
    backend_dir = Path(__file__).resolve().parent.parent
    sys.path.insert(0, str(backend_dir))

