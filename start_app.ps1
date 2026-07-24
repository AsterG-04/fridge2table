<#
.SYNOPSIS
    Local dev convenience script - starts the FastAPI backend, waits for it
    to be ready, then runs the Flutter frontend. Stops the backend again
    when the frontend exits (for any reason: closed, crashed, Ctrl+C).

.PARAMETER ApiBaseUrl
    Optional. Passed to `flutter run` as --dart-define=API_BASE_URL=...
    Only needed when running on a real physical device - pass your
    machine's LAN IP, e.g. -ApiBaseUrl "http://192.168.1.129:8000".
    Leave unset for the emulator (which uses the 10.0.2.2 default).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File start_app.ps1

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File start_app.ps1 -ApiBaseUrl "http://192.168.1.129:8000"

.NOTE
    Local development convenience only - not how the backend gets deployed
    for real (that's Phase 13).
#>

param(
    [string]$ApiBaseUrl = ""
)

$ErrorActionPreference = "Stop"

$backendDir = Join-Path $PSScriptRoot "backend"
$frontendDir = Join-Path $PSScriptRoot "frontend\fridge2table_app"
$venvPython = Join-Path $backendDir "venv\Scripts\python.exe"
$backendOutLog = Join-Path $PSScriptRoot "backend_dev.log"
$backendErrLog = Join-Path $PSScriptRoot "backend_dev.err.log"

if (-not (Test-Path $venvPython)) {
    Write-Error "Backend venv not found at $venvPython. Create it first: cd backend; python -m venv venv; venv\Scripts\pip install -r requirements.txt"
    exit 1
}

Write-Host "Starting backend (uvicorn)..." -ForegroundColor Cyan
$backendProcess = Start-Process -FilePath $venvPython `
    -ArgumentList "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000" `
    -WorkingDirectory $backendDir `
    -WindowStyle Hidden `
    -RedirectStandardOutput $backendOutLog `
    -RedirectStandardError $backendErrLog `
    -PassThru

Write-Host "Checking for a connected physical device (adb devices)..." -ForegroundColor Cyan
try {
    $adbOutput = & adb devices 2>&1
    # Lines look like "XXXXXXXX    device" or "emulator-5554    device" --
    # only the non-"emulator-*" ones are real hardware that needs the USB
    # port forward; the emulator already reaches the host via 10.0.2.2.
    $physicalDevices = $adbOutput |
        Where-Object { $_ -match "^\S+\s+device\s*$" -and $_ -notmatch "^emulator-" }

    if ($physicalDevices.Count -gt 0) {
        Write-Host "Physical device detected -- running adb reverse tcp:8000 tcp:8000..." -ForegroundColor Cyan
        & adb reverse tcp:8000 tcp:8000
        if ($LASTEXITCODE -eq 0) {
            Write-Host "adb reverse is set up -- the device can reach the backend at localhost:8000." -ForegroundColor Green
        } else {
            Write-Warning "adb reverse failed. Run it manually: adb reverse tcp:8000 tcp:8000"
        }
    } else {
        Write-Host "No physical device detected (emulator-only or nothing connected) -- skipping adb reverse." -ForegroundColor DarkGray
    }
} catch {
    Write-Warning "Couldn't run adb (is it on PATH?) -- if testing on a real USB device, run manually: adb reverse tcp:8000 tcp:8000"
}

Write-Host "Waiting for backend to be ready..." -ForegroundColor Cyan
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 1
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/" -UseBasicParsing -TimeoutSec 2
        if ($response.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        # Not ready yet - keep polling.
    }
}

if ($ready) {
    Write-Host "Backend is ready (pid $($backendProcess.Id))." -ForegroundColor Green
} else {
    Write-Warning "Backend didn't respond within 30 seconds. Check $backendErrLog for errors. Continuing anyway."
}

try {
    Write-Host "Starting frontend (flutter run)..." -ForegroundColor Cyan
    Push-Location $frontendDir
    if ($ApiBaseUrl -ne "") {
        flutter run --dart-define=API_BASE_URL=$ApiBaseUrl
    } else {
        flutter run
    }
} finally {
    Pop-Location
    Write-Host "Frontend closed - stopping backend (pid $($backendProcess.Id))..." -ForegroundColor Cyan
    if ($backendProcess -and -not $backendProcess.HasExited) {
        Stop-Process -Id $backendProcess.Id -Force
    }
    Write-Host "Backend stopped." -ForegroundColor Green
}
