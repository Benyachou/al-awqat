<#
.SYNOPSIS
    Pipeline de release Al-awqat : incrémente la version, construit l'APK
    release, puis commit + push sur `main`.

.DESCRIPTION
    Le push sur `main` déclenche la CI GitHub (.github/workflows/build.yml) qui
    reconstruit l'APK et publie une Release taguée « vX.Y.Z-build{N} » à partir
    de la version de pubspec.yaml. Ce script fait la même chose en local (pour
    avoir l'APK tout de suite) ET prépare un numéro de build unique afin que le
    tag de la CI n'entre jamais en collision.

.PARAMETER Message
    Message de commit. Par défaut « Release ».

.PARAMETER Bump
    Partie de version à incrémenter : none | build | patch | minor | major.
    Par défaut « build » (incrémente seulement le +N).

.PARAMETER SkipApk
    Ne construit pas l'APK localement (laisse la CI s'en charger après le push).

.PARAMETER NoPush
    Construit et commit, mais ne pousse pas (utile pour vérifier avant d'envoyer).

.EXAMPLE
    ./scripts/release.ps1 -Message "Onglet horloge 24h" -Bump minor
#>
param(
    [string]$Message = "Release",
    [ValidateSet('none', 'build', 'patch', 'minor', 'major')]
    [string]$Bump = 'build',
    [switch]$SkipApk,
    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

# Se place à la racine du repo (le script est dans scripts/).
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }

# --- 1. Lecture + incrément de version dans pubspec.yaml ---------------------
$pubspecPath = Join-Path $repoRoot 'pubspec.yaml'
$content = Get-Content $pubspecPath -Raw
if ($content -notmatch "(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$") {
    throw "Ligne 'version: X.Y.Z+N' introuvable dans pubspec.yaml"
}
$maj = [int]$Matches[1]; $min = [int]$Matches[2]; $pat = [int]$Matches[3]; $bld = [int]$Matches[4]

switch ($Bump) {
    'build' { $bld++ }
    'patch' { $pat++; $bld++ }
    'minor' { $min++; $pat = 0; $bld++ }
    'major' { $maj++; $min = 0; $pat = 0; $bld++ }
    'none' { }
}
$newVersion = "$maj.$min.$pat+$bld"
$ciTag = "v$maj.$min.$pat-build$bld"

Step "Version : $newVersion  (tag CI attendu : $ciTag)"
$content = $content -replace "(?m)^version:\s*.*$", "version: $newVersion"
# Écrit en UTF-8 SANS BOM pour ne pas perturber les outils Dart/Flutter.
[System.IO.File]::WriteAllText($pubspecPath, $content, (New-Object System.Text.UTF8Encoding($false)))

# --- 2. Dépendances ----------------------------------------------------------
Step "flutter pub get"
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get a échoué" }

# --- 3. Build APK release ----------------------------------------------------
if (-not $SkipApk) {
    Step "flutter build apk --release"
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw "Le build APK a échoué" }
    $apk = Join-Path $repoRoot 'build/app/outputs/flutter-apk/app-release.apk'
    if (Test-Path $apk) {
        $sizeMb = [math]::Round((Get-Item $apk).Length / 1MB, 1)
        Write-Host "APK : $apk ($sizeMb Mo)" -ForegroundColor Green
    }
}
else {
    Step "Build APK ignoré (-SkipApk) — la CI le construira au push"
}

# --- 4. Commit + push --------------------------------------------------------
Step "git commit"
git add -A
git commit -m "$Message (v$newVersion)"
if ($LASTEXITCODE -ne 0) { throw "git commit a échoué (rien à committer ?)" }

if ($NoPush) {
    Write-Host "`n-NoPush : commit créé mais pas poussé. 'git push origin main' quand tu veux." -ForegroundColor Yellow
    return
}

Step "git push origin main"
git push origin main
if ($LASTEXITCODE -ne 0) { throw "git push a échoué" }

Write-Host "`nPoussé. La CI va publier la Release '$ciTag' sous peu :" -ForegroundColor Green
Write-Host "  https://github.com/Benyachou/al-awqat/releases/tag/$ciTag"
Write-Host "  Suivi du build : https://github.com/Benyachou/al-awqat/actions"
