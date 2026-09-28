# Installs everything needed to run Quran Quizz (Windows). Usage: .\scripts\setup.ps1 [-WithServer]
param([switch]$WithServer)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js 22+ is required: https://nodejs.org' }
$major = [int](node -p "process.versions.node.split('.')[0]")
if ($major -lt 22) { throw "Node.js 22+ is required (found $(node -v))." }

Write-Host '==> Installing app dependencies'
$env:CYPRESS_INSTALL_BINARY = '0'
npm ci
if ($LASTEXITCODE) { exit $LASTEXITCODE }

if ($WithServer) {
  $server = '..\quranquizz_server'
  if (-not (Test-Path $server)) { git clone https://github.com/sajouaou/quranquizz_server.git $server }
  Push-Location $server; npm install --no-audit --no-fund; Pop-Location
}
Write-Host 'Done. Start the app with: .\scripts\run.ps1 dev'
