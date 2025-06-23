# jewtube_installer.ps1

$zipUrl = "https://github.com/stoorax/jewtube/archive/refs/heads/main.zip"
$installDir = "$env:USERPROFILE\JewTubeClient"

if (Test-Path $installDir) {
    Write-Output "Alte Installation wird gelöscht..."
    Remove-Item -Recurse -Force $installDir
}
New-Item -ItemType Directory -Path $installDir | Out-Null

Write-Output "Lade Client von GitHub herunter..."
Invoke-WebRequest -Uri $zipUrl -OutFile (Join-Path $installDir "client.zip")

Write-Output "Entpacke Client..."
Expand-Archive -Path (Join-Path $installDir "client.zip") -DestinationPath $installDir -Force
Remove-Item (Join-Path $installDir "client.zip")

$extractedFolder = Get-ChildItem -Path $installDir -Directory | Where-Object { $_.Name -like "*jewtube*" } | Select-Object -First 1
$clientFolder = $extractedFolder.FullName

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python 3.8+ nicht installiert oder nicht im PATH. Bitte installiere Python vor der Nutzung."
    exit 1
}

$version = python --version 2>&1
if ($version -notmatch "Python 3\.[8-9]|Python [4-9]") {
    Write-Error "Python Version 3.8 oder höher wird benötigt. Gefunden: $version"
    exit 1
}

Write-Output "Erstelle virtuelle Umgebung..."
python -m venv (Join-Path $clientFolder "venv")

$venvActivate = Join-Path $clientFolder "venv\Scripts\Activate.ps1"
$packages = @("ytmusicapi", "yt-dlp", "browser_cookie3")

$installScript = @"
`$ErrorActionPreference = 'Stop'
. '$venvActivate'
python -m pip install --upgrade pip
python -m pip install $($packages -join ' ')
"@

$installScriptPath = Join-Path $clientFolder "install_venv.ps1"
$installScript | Out-File -Encoding UTF8 -FilePath $installScriptPath
powershell -ExecutionPolicy Bypass -File $installScriptPath
Remove-Item $installScriptPath

$startBat = Join-Path $clientFolder "start_client.bat"
if (Test-Path $startBat) {
    Write-Output "Starte Client..."
    Start-Process -FilePath $startBat
} else {
    Write-Error "Startdatei 'start_client.bat' nicht gefunden im Ordner $clientFolder"
}
