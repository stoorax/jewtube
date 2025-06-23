# check_env.ps1
Write-Output "=== Umgebung prüfen für yt-dlp & Co. ==="

# 1. Python prüfen
Write-Output "Prüfe Python Installation..."
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $pythonCmd) {
    Write-Warning "Python wurde nicht gefunden!"
} else {
    $version = python --version 2>&1
    if ($version -match "Python 3\.[8-9]|Python [4-9]") {
        Write-Output "Python Version OK: $version"
    } else {
        Write-Warning "Python Version veraltet oder nicht kompatibel: $version"
    }
}

# 2. Pip prüfen
Write-Output "Prüfe pip..."
$pipCmd = Get-Command pip -ErrorAction SilentlyContinue
if ($null -eq $pipCmd) {
    Write-Warning "pip nicht gefunden!"
} else {
    $pipVersion = pip --version 2>&1
    Write-Output "pip gefunden: $pipVersion"
}

# 3. yt-dlp prüfen
Write-Output "Prüfe yt-dlp..."
try {
    $ytDlpVersion = yt-dlp --version 2>&1
    Write-Output "yt-dlp gefunden: Version $ytDlpVersion"
} catch {
    Write-Warning "yt-dlp nicht gefunden!"
}

# 4. ytmusicapi Modul prüfen (in Python)
Write-Output "Prüfe Python-Modul ytmusicapi..."
try {
    python -c "import ytmusicapi" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "ytmusicapi installiert."
    } else {
        Write-Warning "ytmusicapi nicht installiert."
    }
} catch {
    Write-Warning "Fehler beim Prüfen von ytmusicapi."
}

# 5. browser_cookie3 prüfen
Write-Output "Prüfe Python-Modul browser_cookie3..."
try {
    python -c "import browser_cookie3" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Output "browser_cookie3 installiert."
    } else {
        Write-Warning "browser_cookie3 nicht installiert."
    }
} catch {
    Write-Warning "Fehler beim Prüfen von browser_cookie3."
}

Write-Output "=== Prüfung abgeschlossen ==="
