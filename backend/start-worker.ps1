param([Parameter(Mandatory = $true)][string]$FirebaseCredentials)
$ErrorActionPreference = 'Stop'
$credentialsPath = (Resolve-Path -LiteralPath $FirebaseCredentials).Path
Set-Location -LiteralPath $PSScriptRoot
$env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
try { $Host.UI.RawUI.WindowTitle = 'SoundSight - Processing Worker' } catch {}
& "$PSScriptRoot\venv\Scripts\python.exe" -u -m jobs.worker
exit $LASTEXITCODE
