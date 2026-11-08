param(
    [Parameter(Mandatory = $true)][string]$FirebaseCredentials,
    [string]$BindAddress = '127.0.0.1',
    [int]$Port = 8000
)
$ErrorActionPreference = 'Stop'
$credentialsPath = (Resolve-Path -LiteralPath $FirebaseCredentials).Path
Set-Location -LiteralPath $PSScriptRoot
$env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
try { $Host.UI.RawUI.WindowTitle = 'SoundSight - API Requests' } catch {}
& "$PSScriptRoot\venv\Scripts\python.exe" -u -m uvicorn main:app --host $BindAddress --port $Port --workers 1 --no-access-log
exit $LASTEXITCODE
