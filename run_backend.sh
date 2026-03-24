cd c:\Users\hp\Downloads\hadrami_project\backend
python -m venv venv
.\venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload