param(
    [string]$FirebaseCredentials = (Join-Path $env:USERPROFILE 'SoundSightKeys\soundsight-service-account.json'),
    [switch]$CheckOnly
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
    $powerShellPath = Join-Path $PSHOME 'powershell.exe'
    if (-not (Test-Path -LiteralPath $powerShellPath -PathType Leaf)) {
        $powerShellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
    }

    if ($CheckOnly) {
        Write-Output 'Launcher checks passed. No services were started.'
        exit 0
    }

    # Visible windows let the host read logs and stop each service with Ctrl+C.
    # Invoke the existing scripts directly; activating the venv is unnecessary.
    foreach ($service in @('start-worker.ps1', 'start-backend.ps1')) {
        $servicePath = Join-Path $PSScriptRoot $service
        $serviceArguments = @(
            '-NoLogo', '-NoProfile', '-NoExit', '-ExecutionPolicy', 'Bypass',
            '-File', ('"{0}"' -f $servicePath),
            '-FirebaseCredentials', ('"{0}"' -f $credentialsPath)
        )
        if ($service -eq 'start-backend.ps1') {
            $serviceArguments += @('-BindAddress', '0.0.0.0')
        }
        Start-Process -FilePath $powerShellPath -ArgumentList $serviceArguments `
            -WorkingDirectory $PSScriptRoot -WindowStyle Normal
    }
    Write-Output 'SoundSight startup requested. Two windows will open:'
    Write-Output '  API Requests: actions requested by the app and their HTTP responses.'
    Write-Output '  Processing Worker: queued jobs starting, completing, or failing.'
    Write-Output 'Wait for the worker to report Ready. Check http://127.0.0.1:8000/health for readiness.'
    Write-Output 'An HTTP 202 means the job was accepted; completion is reported separately.'
} catch {
    Write-Host ('SoundSight could not start: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
