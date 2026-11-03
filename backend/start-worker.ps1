param([Parameter(Mandatory = $true)][string]$FirebaseCredentials)
$ErrorActionPreference = 'Stop'
$credentialsPath = (Resolve-Path -LiteralPath $FirebaseCredentials).Path
Set-Location -LiteralPath $PSScriptRoot
$env:GOOGLE_APPLICATION_CREDENTIALS = $credentialsPath
& "$PSScriptRoot\venv\Scripts\python.exe" -m jobs.worker
exit $LASTEXITCODE
