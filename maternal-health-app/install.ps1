param(
    [switch]$SkipFlutter,
    [switch]$SkipBackend
)

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $projectDir 'backend'
$mobileDir = Join-Path $projectDir 'apps\mobile'

if (-not $SkipBackend) {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw 'Python 3.10+ is required. Install Python and ensure "python" is on PATH.'
    }

    # Avoid quotes inside the Python expression: Windows PowerShell may strip
    # them while building native command arguments.
    $pythonVersionParts = & python -c 'import sys; print(sys.version_info.major, sys.version_info.minor)'
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($pythonVersionParts -join ' '))) {
        throw 'Could not determine the Python version. Check that Python is installed and on PATH.'
    }
    $parts = ($pythonVersionParts -join ' ').Trim() -split '\s+'
    $pythonVersion = "$($parts[0]).$($parts[1])"
    if ([int]$parts[0] -lt 3 -or ([int]$parts[0] -eq 3 -and [int]$parts[1] -lt 10)) {
        throw "Python 3.10 or newer is required; found $pythonVersion."
    }

    $venvPython = Join-Path $backendDir '.venv\Scripts\python.exe'
    if (-not (Test-Path $venvPython)) {
        & python -m venv (Join-Path $backendDir '.venv')
        if ($LASTEXITCODE -ne 0) { throw 'Failed to create backend virtual environment.' }
    }

    & $venvPython -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) { throw 'Failed to upgrade pip.' }
    & $venvPython -m pip install -r (Join-Path $backendDir 'requirements.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Failed to install backend requirements.' }

    $backendEnv = Join-Path $backendDir '.env'
    if (-not (Test-Path $backendEnv)) {
        Copy-Item (Join-Path $backendDir '.env.example') $backendEnv
        Write-Host 'Created backend\.env from .env.example; set DATABASE_URL and Supabase values before running.' -ForegroundColor Yellow
    }
}

if (-not $SkipFlutter) {
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Flutter SDK is required. Install Flutter and ensure "flutter" is on PATH.'
    }

    Push-Location $mobileDir
    try {
        if (-not (Test-Path '.env')) {
            Copy-Item '.env.example' '.env'
            Write-Host 'Created apps\mobile\.env from .env.example; set your Supabase URL and anon key.' -ForegroundColor Yellow
        }
        & flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
    }
    finally {
        Pop-Location
    }
}

Write-Host 'Dependency installation finished.' -ForegroundColor Green
