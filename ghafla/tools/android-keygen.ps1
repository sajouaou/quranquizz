# Crée la clé de signature Android (clé d'importation) pour le Google Play Store — Windows PowerShell.
#   .\tools\android-keygen.ps1
#   .\tools\android-keygen.ps1 -Name "Prénom Nom" -Org "Mon studio" -Country FR
# Résultat dans $env:USERPROFILE\.ghafla-keys (jamais dans le dépôt) : ghafla-upload.jks, keystore.env.ps1,
# upload_certificate.pem, FINGERPRINTS.txt. Sauvegarde le .jks et le mot de passe ailleurs.
param(
    [string]$Dir = (Join-Path $env:USERPROFILE ".ghafla-keys"),
    [string]$Alias = "ghafla-upload",
    [int]$Years = 30,
    [string]$Name = "",
    [string]$Org = "",
    [string]$Unit = "Jeux",
    [string]$City = "",
    [string]$State = "",
    [string]$Country = ""
)
$ErrorActionPreference = "Stop"

function Find-Keytool {
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\keytool.exe")) { return "$env:JAVA_HOME\bin\keytool.exe" }
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($p in @("$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe", "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe")) {
        if (Test-Path $p) { return $p }
    }
    return $null
}
$keytool = Find-Keytool
if (-not $keytool) { Write-Host "keytool introuvable : installe un JDK 17+ (ou Android Studio) et/ou définis JAVA_HOME." -ForegroundColor Red; exit 1 }

$keystore = Join-Path $Dir "ghafla-upload.jks"
if (Test-Path $keystore) { Write-Host "Il existe déjà une clé : $keystore. Je ne l'écrase pas." -ForegroundColor Red; exit 1 }

function Ask([string]$value, [string]$question, [string]$default) {
    if ($value) { return $value }
    $v = Read-Host "$question [$default]"
    if ($v) { return $v } else { return $default }
}
$Name = Ask $Name "Ton nom ou celui de ton studio" "Ghafla"
$Org = Ask $Org "Organisation" $Name
$City = Ask $City "Ville" "Ville"
$State = Ask $State "Région (facultatif)" "Etat"
$Country = Ask $Country "Pays (2 lettres, ex. FR)" "FR"

$pass = $env:GHAFLA_KEY_PASSWORD
if (-not $pass) {
    $s1 = Read-Host "Mot de passe de la clé (8 caractères minimum)" -AsSecureString
    $s2 = Read-Host "Confirme" -AsSecureString
    $pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s1))
    $pass2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s2))
    if ($pass -ne $pass2) { Write-Host "Les mots de passe diffèrent." -ForegroundColor Red; exit 1 }
}
if ($pass.Length -lt 8) { Write-Host "Mot de passe trop court (8 caractères minimum)." -ForegroundColor Red; exit 1 }

function Clean([string]$s) { return ($s -replace '[,=+<>#;"\\]', '') }
$dname = "CN=$(Clean $Name), OU=$(Clean $Unit), O=$(Clean $Org), L=$(Clean $City), ST=$(Clean $State), C=$(Clean $Country)"

New-Item -ItemType Directory -Force -Path $Dir | Out-Null
& $keytool -genkeypair -v -keystore $keystore -alias $Alias -keyalg RSA -keysize 4096 -validity ($Years * 365) -storepass $pass -keypass $pass -dname $dname
if ($LASTEXITCODE -ne 0) { exit 1 }

@"
`$env:GODOT_ANDROID_KEYSTORE_RELEASE_PATH = "$keystore"
`$env:GODOT_ANDROID_KEYSTORE_RELEASE_USER = "$Alias"
`$env:GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD = "$pass"
"@ | Set-Content -Encoding UTF8 (Join-Path $Dir "keystore.env.ps1")
& $keytool -export -rfc -keystore $keystore -alias $Alias -storepass $pass -file (Join-Path $Dir "upload_certificate.pem") | Out-Null
& $keytool -list -v -keystore $keystore -alias $Alias -storepass $pass | Select-String "SHA1|SHA256|Owner|Propriétaire|Valid|Valide" | Set-Content (Join-Path $Dir "FINGERPRINTS.txt")

Write-Host ""
Write-Host "Clé créée dans $Dir" -ForegroundColor Green
Get-Content (Join-Path $Dir "FINGERPRINTS.txt")
Write-Host ""
Write-Host "Sauvegarde ghafla-upload.jks et son mot de passe AILLEURS. Ne la commit jamais."
Write-Host "Pour construire ensuite (Git Bash / WSL) : tools/android-release.sh build --bump"
Write-Host "Ou dans PowerShell :  . '$Dir\keystore.env.ps1' ; puis exporte depuis Godot (Projet > Exporter)."
