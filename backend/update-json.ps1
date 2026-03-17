# Regenerate hadrami_dataset.json from hadrami_dataset_final.csv
# IMPORTANT: Save the CSV file in your editor (Ctrl+S) before running this.
Set-Location $PSScriptRoot
$csv = Join-Path $PSScriptRoot "data\hadrami_dataset_final.csv"
$json = Join-Path $PSScriptRoot "data\hadrami_dataset.json"
python scripts/csv_to_json.py $csv $json
Write-Host "Done. Restart the backend (run.ps1) to load the new data."
