param(
    [string]$CloudflaredPath = (Join-Path $env:USERPROFILE 'Downloads\cloudflared-windows-amd64.exe'),
    [string]$FirebaseCredentials = (Join-Path $env:USERPROFILE 'SoundSightKeys\soundsight-service-account.json')
)

$ErrorActionPreference = 'Stop'
try {
    $pythonPath = Join-Path $PSScriptRoot 'venv\Scripts\python.exe'
    if (-not (Test-Path -LiteralPath $pythonPath -PathType Leaf)) {
        throw 'The backend virtual environment was not found.'
    }
    $tunnelArguments = @(
        (Join-Path $PSScriptRoot 'quick_tunnel.py'),
        '--cloudflared', $CloudflaredPath,
        '--credentials', $FirebaseCredentials
    )
    & $pythonPath @tunnelArguments
    exit $LASTEXITCODE
} catch {
    Write-Host ('SoundSight tunnel could not start: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
