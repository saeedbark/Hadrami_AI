# Run Hadrami NLP Backend (Windows PowerShell)
Set-Location $PSScriptRoot
pip install -r requirements.txt -q
Write-Host "Starting Hadrami API on http://localhost:8000" -ForegroundColor Green
Write-Host "Docs: http://localhost:8000/docs" -ForegroundColor Cyan
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
