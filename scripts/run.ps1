# Runs Quran Quizz (Windows). Usage: .\scripts\run.ps1 [dev|dev-local|host|build|preview|test|android]
param([string]$Command = 'dev')
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Test-Path node_modules)) { & "$PSScriptRoot\setup.ps1" }

switch ($Command) {
  'dev' { npm run dev }
  'host' { npm run dev -- --host }
  'dev-local' {
    $server = Resolve-Path '..\quranquizz_server' -ErrorAction SilentlyContinue
    if (-not $server -or -not (Test-Path "$server\node_modules")) { & "$PSScriptRoot\setup.ps1" -WithServer; $server = Resolve-Path '..\quranquizz_server' }
    $env:PORT = '5000'
    $proc = Start-Process node -ArgumentList 'index.js' -WorkingDirectory $server -PassThru -NoNewWindow
    try { $env:VITE_SERVER_URL = 'ws://localhost:5000'; npm run dev } finally { Stop-Process -Id $proc.Id -ErrorAction SilentlyContinue }
  }
  'build' { npm run build }
  'preview' { npm run build; npx vite preview --host }
  'test' { npm run lint; npm run test.unit }
  'android' { npm run android }
  default { Write-Host 'Commands: dev, dev-local, host, build, preview, test, android'; exit 1 }
}
