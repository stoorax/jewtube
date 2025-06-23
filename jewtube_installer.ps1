# jewtube_installer.ps1

function Install-Python {
    Write-Output "Prüfe Python Installation..."
    $pythonCmd = Get-Command python -ErrorAction SilentlyContinue

    if ($null -eq $pythonCmd) {
        Write-Output "Python nicht gefunden. Starte automatische Installation..."

        $pythonVersion = "3.11.5"  # aktuelle Version anpassen falls nötig
        $installerUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-amd64.exe"
        $installerPath = "$env:TEMP\python_installer.exe"

        Write-Output "Lade Python $pythonVersion Installer herunter..."
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

        Write-Output "Installiere Python still im Hintergrund..."
        Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait

        Remove-Item $installerPath

        Write-Output "Python Installation abgeschlossen."

        # Warte etwas, damit PATH aktualisiert wird
        Start-Sleep -Seconds 5
    } else {
        Write-Output "Python gefunden unter $($pythonCmd.Path)"
    }
}

function Refresh-Path {
    # PATH aus Machine + User Variablen neu holen und an aktuelle Session anhängen
    $machinePath = [System.Environment]::GetEnvironmentVariable("PATH", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
    $newPath = "$machinePath;$userPath"
    $env:PATH = $newPath
    Write-Output "PATH aktualisiert."
}

function Check-PythonVersion {
    $versionStr = ""
    try {
        $versionStr = python --version 2>&1
    } catch {
        return $false
    }
    return $versionStr -match "Python 3\.[8-9]|Python [4-9]"
}

# --- Hauptablauf ---

Install-Python
Refresh-Path

if (-not (Check-PythonVersion)) {
    Write-Error "Python 3.8+ wird benötigt. Bitte starte die PowerShell neu und führe das Skript erneut aus."
    exit 1
}

# Installation der Client-App

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
