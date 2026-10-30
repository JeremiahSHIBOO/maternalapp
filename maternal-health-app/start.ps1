param(
    [string]$Device
)

$ErrorActionPreference = 'Stop'
$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $projectDir 'backend'
$mobileDir = Join-Path $projectDir 'apps\mobile'
$backendEnv = Join-Path $backendDir '.env'
$mobileEnv = Join-Path $mobileDir '.env'
$venvPython = Join-Path $backendDir '.venv\Scripts\python.exe'

if (-not (Test-Path $backendEnv)) {
    throw 'Backend .env is missing. Run .\install.ps1 first, then configure backend\.env.'
}
if (-not (Test-Path $mobileEnv)) {
    throw 'Mobile .env is missing. Run .\install.ps1 first, then configure apps\mobile\.env.'
}
if (-not (Test-Path $venvPython)) {
    throw 'Backend dependencies are missing. Run .\install.ps1 first.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter SDK is required and must be on PATH.'
}

# Use separate PowerShell windows so Flutter device selection and logs stay visible.
$backendCommand = "Set-Location -LiteralPath '$backendDir'; & '.\.venv\Scripts\python.exe' -m app.main"
Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $backendCommand) -WorkingDirectory $backendDir

$flutterCommand = if ([string]::IsNullOrWhiteSpace($Device)) {
    'flutter run'
} else {
    "flutter run -d '$($Device.Replace("'", "''"))'"
}
Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit', '-ExecutionPolicy', 'Bypass', '-Command', $flutterCommand) -WorkingDirectory $mobileDir

Write-Host 'Started the FastAPI backend and Flutter app in separate PowerShell windows.' -ForegroundColor Green
Write-Host 'Backend: http://127.0.0.1:8000  |  API docs: http://127.0.0.1:8000/docs'
Write-Host 'Close each window or press Ctrl+C in it to stop that process.'
