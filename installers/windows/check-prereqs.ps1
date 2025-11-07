# PacketReporter - Windows Prerequisites Check Script
# Checks system for required and optional dependencies
# Run with: powershell -ExecutionPolicy Bypass -File check-prereqs.ps1
#
# Note: All external command calls redirect stderr to $null to suppress
# console windows during version checks. This provides a cleaner experience.

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"  # Continue to check all prerequisites

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Success { Write-ColorOutput Green "✓ $args" }
function Write-Warning { Write-ColorOutput Yellow "⚠ $args" }
function Write-Error { Write-ColorOutput Red "✗ $args" }
function Write-Info { Write-ColorOutput Cyan "→ $args" }
function Write-Header { Write-ColorOutput Blue $args }

Write-Header "============================================"
Write-Header "PacketReporter - Prerequisites Check"
Write-Header "Version 0.2.0 (Public Beta)"
Write-Header "============================================"
Write-Output ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    Write-Success "Running as Administrator"
} else {
    Write-Warning "Not running as Administrator (some checks may be limited)"
}
Write-Output ""

# Track overall status
$allRequired = $true
$allOptional = $true

#============================================
# Required Dependencies
#============================================
Write-Header "REQUIRED DEPENDENCIES"
Write-Header "--------------------------------------------"
Write-Output ""

# Check for Wireshark
Write-Info "Checking for Wireshark..."
$wiresharkPaths = @(
    "${env:ProgramFiles}\Wireshark\Wireshark.exe",
    "${env:ProgramFiles(x86)}\Wireshark\Wireshark.exe"
)

$wiresharkFound = $false
$wiresharkVersion = $null
foreach ($path in $wiresharkPaths) {
    if (Test-Path $path) {
        $wiresharkFound = $true
        
        # Try to get version
        try {
            $versionInfo = (Get-Item $path).VersionInfo
            $wiresharkVersion = $versionInfo.ProductVersion
            Write-Success "Wireshark found"
            Write-Output "  Version: $wiresharkVersion"
            Write-Output "  Path: $path"
            
            # Check version >= 4.0
            if ($wiresharkVersion -match '^(\d+)\.') {
                $majorVersion = [int]$Matches[1]
                if ($majorVersion -lt 4) {
                    Write-Warning "  Wireshark 4.0+ is recommended (found $wiresharkVersion)"
                } else {
                    Write-Success "  Version meets requirements (4.0+)"
                }
            }
        } catch {
            Write-Success "Wireshark found at $path"
            Write-Warning "  Could not determine version"
        }
        break
    }
}

if (-not $wiresharkFound) {
    Write-Error "Wireshark not found"
    Write-Output "  Required for: PacketReporter plugin"
    Write-Output "  Install from: https://www.wireshark.org/download.html"
    $allRequired = $false
}
Write-Output ""

# Check for Npcap (packet capture driver)
Write-Info "Checking for Npcap (packet capture driver)..."
try {
    $npcap = Get-Service npcap -ErrorAction SilentlyContinue
    if ($npcap) {
        Write-Success "Npcap service found"
        Write-Output "  Status: $($npcap.Status)"
        if ($npcap.Status -ne "Running") {
            Write-Warning "  Npcap service is not running"
        }
    } else {
        Write-Warning "Npcap service not found"
        Write-Output "  Note: Usually installed with Wireshark"
        Write-Output "  Manual install: https://npcap.com/#download"
    }
} catch {
    Write-Warning "Unable to check Npcap status"
}
Write-Output ""

#============================================
# Optional Dependencies (PDF Export)
#============================================
Write-Header "OPTIONAL DEPENDENCIES (for PDF Export)"
Write-Header "--------------------------------------------"
Write-Output ""

# SVG Converters
Write-Header "SVG Converters (need at least one):"
Write-Output ""

$hasConverter = $false

# Check for rsvg-convert
Write-Info "Checking for rsvg-convert (recommended - fastest)..."
if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
    try {
        $rsvgVersion = (rsvg-convert --version 2>$null) | Select-Object -First 1
        Write-Success "rsvg-convert found"
        Write-Output "  Version: $rsvgVersion"
        $hasConverter = $true
    } catch {
        Write-Success "rsvg-convert found"
        $hasConverter = $true
    }
} else {
    Write-Warning "rsvg-convert not found"
    Write-Output "  Install: choco install rsvg-convert"
    Write-Output "  Manual: https://github.com/miyako/console-rsvg-convert/releases"
}
Write-Output ""

# Check for Inkscape
Write-Info "Checking for Inkscape (alternative)..."
$inkscapePaths = @(
    "${env:ProgramFiles}\Inkscape\bin\inkscape.exe",
    "${env:ProgramFiles(x86)}\Inkscape\bin\inkscape.exe"
)
$inkscapeFound = $false
foreach ($path in $inkscapePaths) {
    if (Test-Path $path) {
        Write-Success "Inkscape found"
        Write-Output "  Path: $path"
        try {
            $inkscapeVersion = (& $path --version 2>$null) | Select-Object -First 1
            Write-Output "  Version: $inkscapeVersion"
        } catch {}
        $inkscapeFound = $true
        $hasConverter = $true
        break
    }
}
if (-not $inkscapeFound) {
    Write-Warning "Inkscape not found"
    Write-Output "  Install: choco install inkscape"
    Write-Output "  Manual: https://inkscape.org/release/"
}
Write-Output ""

# Check for ImageMagick
Write-Info "Checking for ImageMagick (alternative)..."
$magickFound = $false
if (Get-Command magick -ErrorAction SilentlyContinue) {
    try {
        $magickVersion = (magick --version 2>$null) | Select-Object -First 1
        Write-Success "ImageMagick found (magick)"
        Write-Output "  Version: $magickVersion"
        $magickFound = $true
        $hasConverter = $true
    } catch {
        Write-Success "ImageMagick found"
        $magickFound = $true
        $hasConverter = $true
    }
} elseif (Get-Command convert -ErrorAction SilentlyContinue) {
    try {
        $convertVersion = (convert --version 2>$null) | Select-Object -First 1
        Write-Success "ImageMagick found (convert)"
        Write-Output "  Version: $convertVersion"
        $magickFound = $true
        $hasConverter = $true
    } catch {
        Write-Success "ImageMagick found"
        $magickFound = $true
        $hasConverter = $true
    }
}
if (-not $magickFound) {
    Write-Warning "ImageMagick not found"
    Write-Output "  Install: choco install imagemagick"
    Write-Output "  Manual: https://imagemagick.org/script/download.php#windows"
}
Write-Output ""

# PDF Combiners
Write-Header "PDF Combiners (need at least one):"
Write-Output ""

$hasCombiner = $false

# Check for pdfunite
Write-Info "Checking for pdfunite (recommended)..."
if (Get-Command pdfunite -ErrorAction SilentlyContinue) {
    try {
        $pdfuniteVersion = (pdfunite --version 2>$null) | Select-Object -First 1
        Write-Success "pdfunite found"
        Write-Output "  Version: $pdfuniteVersion"
        $hasCombiner = $true
    } catch {
        Write-Success "pdfunite found"
        $hasCombiner = $true
    }
} else {
    Write-Warning "pdfunite not found"
    Write-Output "  Install: choco install poppler"
    Write-Output "  Manual: https://github.com/oschwartz10612/poppler-windows/releases"
}
Write-Output ""

# Check for pdftk
Write-Info "Checking for pdftk (alternative)..."
if (Get-Command pdftk -ErrorAction SilentlyContinue) {
    try {
        $pdftkVersion = (pdftk --version 2>$null) | Select-Object -First 1
        Write-Success "pdftk found"
        Write-Output "  Version: $pdftkVersion"
        $hasCombiner = $true
    } catch {
        Write-Success "pdftk found"
        $hasCombiner = $true
    }
} else {
    Write-Warning "pdftk not found"
    Write-Output "  Install: choco install pdftk"
    Write-Output "  Manual: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/"
}
Write-Output ""

#============================================
# Package Managers
#============================================
Write-Header "PACKAGE MANAGERS"
Write-Header "--------------------------------------------"
Write-Output ""

# Check for Chocolatey
Write-Info "Checking for Chocolatey..."
if (Get-Command choco -ErrorAction SilentlyContinue) {
    try {
        $chocoVersion = (choco --version 2>$null)
        Write-Success "Chocolatey found"
        Write-Output "  Version: $chocoVersion"
    } catch {
        Write-Success "Chocolatey found"
    }
} else {
    Write-Warning "Chocolatey not found (recommended for easy installation)"
    Write-Output "  Install from: https://chocolatey.org/install"
    Write-Output ""
    Write-Output "  Quick install command (run as Administrator):"
    Write-Output "    Set-ExecutionPolicy Bypass -Scope Process -Force;"
    Write-Output "    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;"
    Write-Output "    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
}
Write-Output ""

#============================================
# Plugin Directory Check
#============================================
Write-Header "WIRESHARK PLUGIN DIRECTORY"
Write-Header "--------------------------------------------"
Write-Output ""

$pluginDir = "$env:APPDATA\Wireshark\plugins"
Write-Info "Checking plugin directory..."
if (Test-Path $pluginDir) {
    Write-Success "Plugin directory exists"
    Write-Output "  Path: $pluginDir"
    
    # Check if plugin is already installed
    if (Test-Path "$pluginDir\packet_reporter.lua") {
        Write-Success "  PacketReporter plugin is installed"
        try {
            $luaFile = Get-Item "$pluginDir\packet_reporter.lua"
            Write-Output "  File size: $($luaFile.Length) bytes"
            Write-Output "  Last modified: $($luaFile.LastWriteTime)"
        } catch {}
    } else {
        Write-Info "  PacketReporter plugin not yet installed"
    }
} else {
    Write-Info "Plugin directory does not exist yet"
    Write-Output "  Will be created during installation: $pluginDir"
}
Write-Output ""

#============================================
# Summary
#============================================
Write-Header "============================================"
Write-Header "SUMMARY"
Write-Header "============================================"
Write-Output ""

if ($allRequired) {
    Write-Success "All required dependencies are installed"
} else {
    Write-Error "Some required dependencies are missing"
    Write-Output "  Please install missing required dependencies before proceeding"
}
Write-Output ""

if ($hasConverter -and $hasCombiner) {
    Write-Success "All optional dependencies for PDF export are installed"
    Write-Output "  Full PDF export functionality available"
} else {
    Write-Warning "Some optional dependencies are missing"
    if (-not $hasConverter) {
        Write-Output "  • Missing SVG converter (rsvg-convert, Inkscape, or ImageMagick)"
    }
    if (-not $hasCombiner) {
        Write-Output "  • Missing PDF combiner (pdfunite or pdftk)"
    }
    Write-Output ""
    Write-Output "  Plugin will work without these, but PDF export will be unavailable"
}
Write-Output ""

#============================================
# Installation Recommendations
#============================================
if (-not $hasConverter -or -not $hasCombiner) {
    Write-Header "RECOMMENDED INSTALLATION"
    Write-Header "--------------------------------------------"
    Write-Output ""
    
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-ColorOutput Green "Using Chocolatey (easiest method):"
        Write-Output ""
        Write-Output "  Run as Administrator:"
        if (-not $hasConverter -and -not $hasCombiner) {
            Write-ColorOutput Cyan "    choco install rsvg-convert poppler"
        } elseif (-not $hasConverter) {
            Write-ColorOutput Cyan "    choco install rsvg-convert"
        } elseif (-not $hasCombiner) {
            Write-ColorOutput Cyan "    choco install poppler"
        }
    } else {
        Write-ColorOutput Green "Install Chocolatey first (recommended):"
        Write-Output "  https://chocolatey.org/install"
        Write-Output ""
        Write-ColorOutput Green "Or manually install:"
        if (-not $hasConverter) {
            Write-Output ""
            Write-Output "  SVG Converter (choose one):"
            Write-Output "    • librsvg: https://github.com/miyako/console-rsvg-convert/releases"
            Write-Output "    • Inkscape: https://inkscape.org/release/"
            Write-Output "    • ImageMagick: https://imagemagick.org/script/download.php#windows"
        }
        if (-not $hasCombiner) {
            Write-Output ""
            Write-Output "  PDF Combiner (choose one):"
            Write-Output "    • Poppler: https://github.com/oschwartz10612/poppler-windows/releases"
            Write-Output "    • PDFtk: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/"
        }
    }
    Write-Output ""
}

#============================================
# Next Steps
#============================================
Write-Header "NEXT STEPS"
Write-Header "--------------------------------------------"
Write-Output ""

if ($allRequired) {
    Write-Output "  1. Install optional dependencies (if desired for PDF export)"
    Write-Output "  2. Run install.ps1 to install PacketReporter plugin"
    Write-Output "  3. Restart Wireshark"
    Write-Output "  4. Access plugin via: Tools → PacketReporter"
} else {
    Write-Output "  1. Install missing required dependencies (Wireshark)"
    Write-Output "  2. Run this script again to verify installation"
    Write-Output "  3. Install optional dependencies (if desired for PDF export)"
    Write-Output "  4. Run install.ps1 to install PacketReporter plugin"
}
Write-Output ""

#============================================
# Documentation
#============================================
Write-Header "DOCUMENTATION"
Write-Header "--------------------------------------------"
Write-Output ""
Write-Output "  For detailed prerequisites information:"
Write-Output "    installers/windows/requirements.md"
Write-Output ""
Write-Output "  For platform comparison:"
Write-Output "    PLATFORM_PREREQUISITES.md"
Write-Output ""

Write-Header "============================================"
Write-Output ""

# Exit code based on required dependencies
if ($allRequired) {
    exit 0
} else {
    exit 1
}
