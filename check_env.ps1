# check_env.ps1

# Helper-Funktionen für farbige Ausgaben
function Write-WarningColor($message) {
    Write-Host "WARNING: $message" -ForegroundColor Red
}
function Write-SuccessColor($message) {
    Write-Host "SUCCESS: $message" -ForegroundColor Green
}
function Write-Info($message) {
    Write-Host $message -ForegroundColor White
}

Write-Info "=== Checking environment for yt-dlp & related tools ==="

# Check Python
Write-Info "Checking Python installation..."
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $pythonCmd) {
    Write-WarningColor "Python not found!"
    $pythonFound = $false
} else {
    $version = python --version 2>&1
    if ($version -match "Python 3\.[8-9]|Python [4-9]") {
        Write-SuccessColor "Python version OK: $version"
        $pythonFound = $true
    } else {
        Write-WarningColor "Python version incompatible or outdated: $version"
        $pythonFound = $false
    }
}

# Check pip
Write-Info "Checking pip..."
$pipCmd = Get-Command pip -ErrorAction SilentlyContinue
if ($null -eq $pipCmd) {
    Write-WarningColor "pip not found!"
    $pipFound = $false
} else {
    $pipVersion = pip --version 2>&1
    Write-SuccessColor "pip found: $pipVersion"
    $pipFound = $true
}

# Check yt-dlp
Write-Info "Checking yt-dlp..."
try {
    $ytDlpVersion = yt-dlp --version 2>&1
    Write-SuccessColor "yt-dlp found: Version $ytDlpVersion"
    $ytDlpFound = $true
} catch {
    Write-WarningColor "yt-dlp not found!"
    $ytDlpFound = $false
}

# Function to check if python module is installed
function Check-PythonModule($moduleName) {
    $code = "import $moduleName"
    python -c $code 2>$null
    return $LASTEXITCODE -eq 0
}

# Check ytmusicapi
Write-Info "Checking Python module ytmusicapi..."
if ($pythonFound -and (Check-PythonModule "ytmusicapi")) {
    Write-SuccessColor "ytmusicapi is installed."
    $ytmusicapiFound = $true
} else {
    Write-WarningColor "ytmusicapi is NOT installed."
    $ytmusicapiFound = $false
}

# Check browser_cookie3
Write-Info "Checking Python module browser_cookie3..."
if ($pythonFound -and (Check-PythonModule "browser_cookie3")) {
    Write-SuccessColor "browser_cookie3 is installed."
    $browserCookieFound = $true
} else {
    Write-WarningColor "browser_cookie3 is NOT installed."
    $browserCookieFound = $false
}

Write-Info "`n=== Environment check complete ==="

# Optional: automatic install of missing python packages
if ($pythonFound -and $pipFound) {
    $toInstall = @()
    if (-not $ytmusicapiFound) { $toInstall += "ytmusicapi" }
    if (-not $browserCookieFound) { $toInstall += "browser_cookie3" }
    if (-not $ytDlpFound) { $toInstall += "yt-dlp" }

    if ($toInstall.Count -gt 0) {
        Write-Info "`nInstalling missing packages: $($toInstall -join ', ') ..."
        python -m pip install --upgrade pip
        python -m pip install $toInstall

        Write-Info "Re-checking installed packages..."

        # Re-check modules
        if (Check-PythonModule "ytmusicapi") {
            Write-SuccessColor "ytmusicapi successfully installed."
        } else {
            Write-WarningColor "Failed to install ytmusicapi."
        }

        if (Check-PythonModule "browser_cookie3") {
            Write-SuccessColor "browser_cookie3 successfully installed."
        } else {
            Write-WarningColor "Failed to install browser_cookie3."
        }

        try {
            $ytDlpVersion = yt-dlp --version 2>&1
            Write-SuccessColor "yt-dlp successfully installed: Version $ytDlpVersion"
        } catch {
            Write-WarningColor "Failed to install yt-dlp."
        }
    } else {
        Write-SuccessColor "All required packages are installed."
    }
} else {
    Write-WarningColor "Python or pip not available — skipping package installation."
}
