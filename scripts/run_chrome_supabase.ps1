$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$envFile = Join-Path $root ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "Missing .env — copy .env.example to .env and set SUPABASE_URL, SUPABASE_ANON_KEY, FILEZEN_WORKSPACE_ID."
    exit 1
}
flutter run -d chrome --dart-define-from-file=.env
