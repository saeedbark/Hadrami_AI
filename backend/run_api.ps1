# Run API with backend\venv (same env as: pip install -r requirements.txt).
# Upgrade pip once:  .\venv\Scripts\python.exe -m pip install --upgrade pip
Set-Location $PSScriptRoot
& "$PSScriptRoot\venv\Scripts\python.exe" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
