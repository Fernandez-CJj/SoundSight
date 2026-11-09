param(
    [string]$FirebaseCredentials = (Join-Path $env:USERPROFILE 'SoundSightKeys\soundsight-service-account.json')
)

$ErrorActionPreference = 'Stop'

try {
    $requiredFiles = @(
        (Join-Path $PSScriptRoot 'venv\Scripts\python.exe'),
        (Join-Path $PSScriptRoot 'start-backend.ps1'),
        (Join-Path $PSScriptRoot 'start-worker.ps1'),
        $FirebaseCredentials
    )
    foreach ($requiredFile in $requiredFiles) {
        if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
            throw "Required file not found: $requiredFile"
        }
    }
    $credentialsPath = (Resolve-Path -LiteralPath $FirebaseCredentials).Path

    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoLogo', '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}\start-worker.ps1"' -f $PSScriptRoot),
        '-FirebaseCredentials', ('"{0}"' -f $credentialsPath)
    ) -WorkingDirectory $PSScriptRoot -WindowStyle Normal

    Start-Process -FilePath 'powershell.exe' -ArgumentList @(
        '-NoLogo', '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}\start-backend.ps1"' -f $PSScriptRoot),
        '-FirebaseCredentials', ('"{0}"' -f $credentialsPath),
        '-BindAddress', '0.0.0.0'
    ) -WorkingDirectory $PSScriptRoot -WindowStyle Normal

    Write-Output 'API and worker startup requested.'
} catch {
    Write-Host ('SoundSight could not start: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
