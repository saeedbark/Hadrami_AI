#!/bin/bash
# Run Hadrami NLP Backend
cd "$(dirname "$0")"
pip install -r requirements.txt -q
echo "✅ Starting Hadrami API on http://localhost:8000"
echo "📖 Docs: http://localhost:8000/docs"
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
