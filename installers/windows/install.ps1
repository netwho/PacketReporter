# PacketReporter - Windows Installation Script
# Installs the PacketReporter plugin with prerequisite checks
# Run with: powershell -ExecutionPolicy Bypass -File install.ps1
#
# Note: All external command calls redirect stderr to $null to suppress
# console windows. This provides a cleaner installation experience.

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

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
Write-Header "PacketReporter - Windows Installation"
Write-Header "============================================"
Write-Output ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Not running as Administrator (some checks may be limited)"
    Write-Output ""
}

# Prerequisites check
Write-Header "Checking prerequisites..."
Write-Output ""

$prereqFailed = $false

# Check for Wireshark
Write-Info "Checking for Wireshark..."
$wiresharkPaths = @(
    "${env:ProgramFiles}\Wireshark\Wireshark.exe",
    "${env:ProgramFiles(x86)}\Wireshark\Wireshark.exe"
)

$wiresharkFound = $false
$wiresharkPath = $null
foreach ($path in $wiresharkPaths) {
    if (Test-Path $path) {
        $wiresharkFound = $true
        $wiresharkPath = $path
        
        # Try to get version
        try {
            $versionInfo = (Get-Item $path).VersionInfo
            $version = $versionInfo.ProductVersion
            Write-Success "Wireshark found (version: $version)"
            
            # Check version >= 4.0
            if ($version -match '^(\d+)\.') {
                $majorVersion = [int]$Matches[1]
                if ($majorVersion -lt 4) {
                    Write-Warning "Wireshark 4.0+ recommended (found $version)"
                }
            }
        } catch {
            Write-Success "Wireshark found at $path"
        }
        break
    }
}

if (-not $wiresharkFound) {
    Write-Error "Wireshark not found"
    Write-Output "  Install from: https://www.wireshark.org/download.html"
    $prereqFailed = $true
}

# Check for Chocolatey (optional package manager)
Write-Info "Checking for Chocolatey..."
if (Get-Command choco -ErrorAction SilentlyContinue) {
    $chocoVersion = (choco --version 2>$null)
    Write-Success "Chocolatey found (version: $chocoVersion)"
} else {
    Write-Warning "Chocolatey not found (optional but recommended)"
    Write-Output "  Install from: https://chocolatey.org/install"
}

# Exit if critical prerequisites failed
if ($prereqFailed) {
    Write-Output ""
    Write-Error "Installation cannot continue - prerequisites missing"
    Write-Output "  Please install Wireshark and try again."
    exit 1
}

Write-Output ""
Write-Header "Installing plugin..."
Write-Output ""

# Determine plugin directory
$pluginDir = "$env:APPDATA\Wireshark\plugins"

Write-Success "Plugin directory: $pluginDir"

# Create plugin directory if it doesn't exist
if (-not (Test-Path $pluginDir)) {
    Write-Info "Creating plugin directory..."
    New-Item -ItemType Directory -Force -Path $pluginDir | Out-Null
    Write-Success "Directory created"
} else {
    Write-Success "Directory exists"
}

# Copy the plugin file
$luaFile = $null
if (Test-Path "$ScriptDir\packet_reporter.lua") {
    $luaFile = "$ScriptDir\packet_reporter.lua"
} elseif (Test-Path "$ScriptDir\..\..\packet_reporter.lua") {
    $luaFile = "$ScriptDir\..\..\packet_reporter.lua"
}

if ($luaFile) {
    Write-Info "Installing packet_reporter.lua..."
    Copy-Item $luaFile "$pluginDir\packet_reporter.lua" -Force
    Write-Success "Plugin installed"
} else {
    Write-Error "packet_reporter.lua not found"
    exit 1
}

# Create config directory for cover page customization
$configDir = "$env:USERPROFILE\.packet_reporter"
Write-Info "Setting up configuration directory..."

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Force -Path $configDir | Out-Null
    Write-Success "Created config directory: $configDir"
} else {
    Write-Success "Config directory exists"
}

# Copy default logo and description if they don't exist
if ((-not (Test-Path "$configDir\Logo.png")) -and (Test-Path "$ScriptDir\Logo.png")) {
    Copy-Item "$ScriptDir\Logo.png" "$configDir\" -Force
    Write-Success "Copied default logo to $configDir\Logo.png"
} else {
    if (Test-Path "$configDir\Logo.png") {
        Write-Success "Logo already exists in config directory"
    }
}

if ((-not (Test-Path "$configDir\packet_reporter.txt")) -and (Test-Path "$ScriptDir\packet_reporter.txt")) {
    Copy-Item "$ScriptDir\packet_reporter.txt" "$configDir\" -Force
    Write-Success "Copied default description to $configDir\packet_reporter.txt"
} else {
    if (Test-Path "$configDir\packet_reporter.txt") {
        Write-Success "Description file already exists in config directory"
    }
}

# Create tools directory suggestion for console-rsvg-convert
$toolsDir = "C:\Tools"
if (-not (Test-Path $toolsDir)) {
    Write-Info "Creating tools directory for optional dependencies..."
    try {
        New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
        Write-Success "Created tools directory: $toolsDir"
        Write-Info "You can copy console-rsvg-convert.exe here and add to PATH"
    } catch {
        Write-Warning "Could not create tools directory (may require admin): $toolsDir"
    }
} else {
    Write-Success "Tools directory exists: $toolsDir"
}

# Check for PDF export dependencies
Write-Output ""
Write-Header "Checking PDF export dependencies..."
Write-Output ""

$hasConverter = $false
$hasCombiner = $false

# Check for rsvg-convert
Write-Info "Checking for rsvg-convert (SVG to PNG converter)..."
if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
    Write-Success "rsvg-convert found"
    $hasConverter = $true
} else {
    Write-Warning "rsvg-convert not found"
}

# Check for Inkscape (alternative)
Write-Info "Checking for Inkscape (alternative converter)..."
$inkscapePaths = @(
    "${env:ProgramFiles}\Inkscape\bin\inkscape.exe",
    "${env:ProgramFiles(x86)}\Inkscape\bin\inkscape.exe"
)
foreach ($path in $inkscapePaths) {
    if (Test-Path $path) {
        Write-Success "Inkscape found"
        $hasConverter = $true
        break
    }
}
if (-not $hasConverter) {
    Write-Warning "Inkscape not found"
}

# Check for ImageMagick (alternative)
Write-Info "Checking for ImageMagick (alternative converter)..."
if ((Get-Command magick -ErrorAction SilentlyContinue) -or (Get-Command convert -ErrorAction SilentlyContinue)) {
    Write-Success "ImageMagick found"
    $hasConverter = $true
} else {
    Write-Warning "ImageMagick not found"
}

# Check for pdfunite (from poppler)
Write-Info "Checking for pdfunite (PDF combiner)..."
if (Get-Command pdfunite -ErrorAction SilentlyContinue) {
    Write-Success "pdfunite found"
    $hasCombiner = $true
} else {
    Write-Warning "pdfunite not found"
}

# Check for pdftk (alternative)
Write-Info "Checking for pdftk (alternative PDF combiner)..."
if (Get-Command pdftk -ErrorAction SilentlyContinue) {
    Write-Success "pdftk found"
    $hasCombiner = $true
} else {
    Write-Warning "pdftk not found"
}

# Installation recommendations
Write-Output ""
if (-not $hasConverter -or -not $hasCombiner) {
    Write-Warning "Optional dependencies missing (PDF export will be limited)"
    Write-Output ""
    Write-Header "Recommended Tools for PDF Export:"
    Write-Output ""
    Write-ColorOutput Green "  This combination works well:"
    Write-Output ""
    
    if (-not $hasConverter) {
        Write-ColorOutput Cyan "  1. console-rsvg-convert (SVG Converter):"
        Write-Output "     • Download: https://github.com/miyako/console-rsvg-convert/releases"
        Write-Output "     • Copy the single .exe file to a directory in PATH"
        Write-Output "     • Option A: Copy to C:\Windows\ (already in PATH)"
        Write-Output "     • Option B: Copy to C:\Tools\ and add to PATH"
        Write-Output "       (Directory created: $toolsDir)"
        Write-Output ""
    }
    
    if (-not $hasCombiner) {
        Write-ColorOutput Cyan "  2. PDFtk (PDF Combiner):"
        Write-Output "     • Download: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/"
        Write-Output "     • Install PDFtk Free (includes command-line tool)"
        Write-Output "     • Installer will add to PATH automatically"
        Write-Output ""
    }
    
    Write-ColorOutput Yellow "  Alternative tools are also supported (see requirements.md)"
    Write-Output ""
} else {
    Write-Success "All PDF export dependencies are installed"
}

# Final instructions
Write-Output ""
Write-Header "============================================"
Write-ColorOutput Green "✓ Installation Complete!"
Write-Header "============================================"
Write-Output ""
Write-Header "Next steps:"
Write-Output "  1. Restart Wireshark"
Write-Output "  2. Go to: Tools → PacketReporter"
Write-Output "  3. Choose a report type:"
Write-Output "     • Summary Report - Quick overview"
Write-Output "     • Detailed Report (A4) - Comprehensive analysis"
Write-Output "     • Detailed Report (Legal) - US Legal paper size"
Write-Output ""
Write-Header "Customization:"
Write-Output "  Detailed reports include a professional cover page."
Write-Output "  Customize by editing files in: $configDir"
Write-Output "     • Logo.png - Your company/organization logo"
Write-Output "     • packet_reporter.txt - Report description (3 lines max)"
Write-Output ""
Write-Header "Plugin location:"
Write-Output "  $pluginDir\packet_reporter.lua"
Write-Output ""
Write-Header "Generated reports saved to:"
Write-Output "  $env:USERPROFILE\Documents\PacketReporter Reports\"
Write-Output ""
Write-Header "Documentation:"
Write-Output "  • README.md - Full user guide"
Write-Output "  • QUICKSTART.md - Quick start guide"
Write-Output "  • requirements.md - Detailed prerequisites"
Write-Output ""
