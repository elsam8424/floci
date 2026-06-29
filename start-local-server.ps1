param(
    [switch]$Build,
    [int]$HealthTimeoutSec = 60
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Test-DockerRunning {
    docker info 2>&1 | Out-Null
    return $LASTEXITCODE -eq 0
}

function Set-FlociAwsEnv {
    $env:AWS_ENDPOINT_URL = 'http://localhost:4566'
    $env:AWS_DEFAULT_REGION = 'us-east-1'
    $env:AWS_ACCESS_KEY_ID = 'test'
    $env:AWS_SECRET_ACCESS_KEY = 'test'
}

function Wait-FlociHealthy {
    param([string]$Url, [int]$TimeoutSec)

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
            if ($response.StatusCode -eq 200) {
                return $true
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

Write-Host '==> Floci: comprobando Docker...' -ForegroundColor Cyan
if (-not (Test-DockerRunning)) {
    Write-Error 'Docker no responde. Abre Docker Desktop y vuelve a ejecutar el script.'
    exit 1
}

Write-Host '==> Floci: arrancando contenedor...' -ForegroundColor Cyan
if ($Build) {
    docker compose up -d --build
} else {
    docker compose up -d
}
if ($LASTEXITCODE -ne 0) {
    Write-Error "docker compose fallo (codigo $LASTEXITCODE)."
    exit 1
}

$healthUrl = 'http://localhost:4566/_floci/health'
Write-Host "==> Floci: esperando health ($healthUrl)..." -ForegroundColor Cyan
if (-not (Wait-FlociHealthy -Url $healthUrl -TimeoutSec $HealthTimeoutSec)) {
    Write-Error 'Floci no respondio a tiempo. Revisa: docker compose logs -f'
    exit 1
}

Set-FlociAwsEnv

Write-Host ''
Write-Host "Floci listo en $($env:AWS_ENDPOINT_URL)" -ForegroundColor Green
Write-Host 'Variables AWS configuradas.' -ForegroundColor Green
