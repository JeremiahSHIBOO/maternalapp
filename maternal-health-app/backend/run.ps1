# backend/run.ps1 — One-command backend runner
# Loads .env then starts the FastAPI server on http://0.0.0.0:8000
#
# Usage:
#   .\run.ps1
#
# Before first use:
#   1. Edit .env and set DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY
#   2. Run: .\run.ps1

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$envFile = Join-Path $scriptDir ".env"

if (-not (Test-Path $envFile)) {
    Write-Error ".env file not found at $envFile. Copy .env.example to .env and fill in your values."
    exit 1
}

# Load environment variables from .env (simple parser: KEY=VALUE, ignore comments/blank lines)
Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    if ($line -match "^([^=]+)=(.*)$") {
        $key = $Matches[1].Trim()
        $value = $Matches[2].Trim().Trim('"').Trim("'")
        [System.Environment]::SetEnvironmentVariable($key, $value, [System.EnvironmentVariableTarget]::Process)
    }
}

Write-Host "Backend environment loaded from $envFile" -ForegroundColor Green
Write-Host "DATABASE_URL is set: $([bool]([System.Environment]::GetEnvironmentVariable('DATABASE_URL')))" -ForegroundColor Green
Write-Host "Starting FastAPI on http://0.0.0.0:8000 ..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Cyan

python -m app.main
