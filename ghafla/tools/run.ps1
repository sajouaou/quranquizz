# Lance le jeu depuis les sources (Windows).  Usage : .\tools\run.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$godot = $env:GODOT
if (-not $godot) {
    foreach ($name in "godot4", "godot", "Godot") {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { $godot = $cmd.Source; break }
    }
}
if (-not $godot) {
    Write-Host "Godot 4.4 ou plus récent est introuvable." -ForegroundColor Red
    Write-Host "Télécharge-le sur https://godotengine.org/download puis mets-le dans le PATH,"
    Write-Host 'ou lance :  $env:GODOT = "C:\chemin\Godot.exe"; .\tools\run.ps1'
    exit 1
}
& $godot --path . @args
