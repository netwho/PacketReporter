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

function Write-Success { Write-ColorOutput Green "[OK] $args" }
function Write-Warning { Write-ColorOutput Yellow "[!] $args" }
function Write-Error { Write-ColorOutput Red "[X] $args" }
function Write-Info { Write-ColorOutput Cyan "-> $args" }
function Write-Header { Write-ColorOutput Blue $args }

Write-Header "============================================"
Write-Header "PacketReporter - Prerequisites Check"
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
$hasRecommendedConverter = $false
$hasRecommendedCombiner = $false
$hasAnyConverter = $false
$hasAnyCombiner = $false

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
# Recommended Tools (PDF Export)
#============================================
Write-Header "RECOMMENDED TOOLS (for PDF Export)"
Write-Header "--------------------------------------------"
Write-Output ""
Write-Output "These tools work well together and are recommended:"
Write-Output ""

# Check for console-rsvg-convert (Recommended SVG Converter)
Write-Info "Checking for console-rsvg-convert (recommended SVG converter)..."
$rsvgFound = $false
if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
    try {
        # Try to get version - redirect both stdout and stderr
        $rsvgVersion = (rsvg-convert --version 2>&1) | Select-Object -First 1
        if ($rsvgVersion -and $rsvgVersion -notmatch "error|not found") {
            Write-Success "console-rsvg-convert found"
            Write-Output "  Version: $rsvgVersion"
            $rsvgFound = $true
            $hasRecommendedConverter = $true
            $hasAnyConverter = $true
        }
    } catch {
        # If version check fails, try to run it to see if it works
        try {
            $testResult = (rsvg-convert --version 2>&1)
            if ($LASTEXITCODE -eq 0 -or $testResult) {
                Write-Success "console-rsvg-convert found"
                $rsvgFound = $true
                $hasRecommendedConverter = $true
                $hasAnyConverter = $true
            }
        } catch {
            # Command exists but may not work properly
            Write-Warning "console-rsvg-convert command found but may not be working correctly"
        }
    }
}

if (-not $rsvgFound) {
    Write-Warning "console-rsvg-convert not found"
    Write-Output "  Download: https://github.com/miyako/console-rsvg-convert/releases"
    Write-Output "  Copy the single .exe file to a directory in PATH"
    Write-Output "  (e.g., C:\Windows\ or C:\Tools\)"
}
Write-Output ""

# Check for PDFtk (Recommended PDF Combiner)
Write-Info "Checking for PDFtk (recommended PDF combiner)..."
$pdftkFound = $false
$pdftkPath = $null

# Check common installation paths
$pdftkPaths = @(
    "${env:ProgramFiles}\PDFtk\bin\pdftk.exe",
    "${env:ProgramFiles(x86)}\PDFtk\bin\pdftk.exe",
    "${env:ProgramFiles}\PDFtk Server\bin\pdftk.exe",
    "${env:ProgramFiles(x86)}\PDFtk Server\bin\pdftk.exe"
)

# First check if it's in PATH
if (Get-Command pdftk -ErrorAction SilentlyContinue) {
    try {
        $pdftkVersion = (pdftk --version 2>&1) | Select-Object -First 1
        if ($pdftkVersion -and $pdftkVersion -notmatch "error|not found") {
            Write-Success "PDFtk found (in PATH)"
            Write-Output "  Version: $pdftkVersion"
            $pdftkFound = $true
            $hasRecommendedCombiner = $true
            $hasAnyCombiner = $true
        }
    } catch {
        try {
            $testResult = (pdftk --version 2>&1)
            if ($LASTEXITCODE -eq 0 -or $testResult) {
                Write-Success "PDFtk found (in PATH)"
                $pdftkFound = $true
                $hasRecommendedCombiner = $true
                $hasAnyCombiner = $true
            }
        } catch {}
    }
}

# If not in PATH, check common installation directories
if (-not $pdftkFound) {
    foreach ($path in $pdftkPaths) {
        if (Test-Path $path) {
            $pdftkPath = $path
            try {
                $pdftkVersion = (& $path --version 2>&1) | Select-Object -First 1
                Write-Success "PDFtk found"
                Write-Output "  Path: $path"
                if ($pdftkVersion -and $pdftkVersion -notmatch "error|not found") {
                    Write-Output "  Version: $pdftkVersion"
                }
                Write-Warning "  PDFtk is installed but not in PATH"
                Write-Output "  Add to PATH: $($path | Split-Path -Parent)"
                $pdftkFound = $true
                $hasRecommendedCombiner = $true
                $hasAnyCombiner = $true
                break
            } catch {
                Write-Success "PDFtk found at $path"
                Write-Warning "  PDFtk is installed but not in PATH"
                Write-Output "  Add to PATH: $($path | Split-Path -Parent)"
                $pdftkFound = $true
                $hasRecommendedCombiner = $true
                $hasAnyCombiner = $true
                break
            }
        }
    }
}

if (-not $pdftkFound) {
    Write-Warning "PDFtk not found"
    Write-Output "  Download: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/"
    Write-Output "  Install PDFtk Free (includes command-line tool)"
}
Write-Output ""

#============================================
# Alternative Tools (Optional)
#============================================
Write-Header "ALTERNATIVE TOOLS (Optional)"
Write-Header "--------------------------------------------"
Write-Output ""
Write-Output "These alternatives are also supported:"
Write-Output ""

# Check for Inkscape (Alternative SVG Converter)
Write-Info "Checking for Inkscape (alternative SVG converter)..."
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
            $inkscapeVersion = (& $path --version 2>&1) | Select-Object -First 1
            if ($inkscapeVersion) {
                Write-Output "  Version: $inkscapeVersion"
            }
        } catch {}
        $inkscapeFound = $true
        $hasAnyConverter = $true
        break
    }
}
if (-not $inkscapeFound) {
    Write-Info "Inkscape not found (optional)"
}
Write-Output ""

# Check for ImageMagick (Alternative SVG Converter)
# Note: We need to verify it's actually ImageMagick, not Windows' built-in convert command
Write-Info "Checking for ImageMagick (alternative SVG converter)..."
$magickFound = $false

# First check for 'magick' command (ImageMagick 7+)
if (Get-Command magick -ErrorAction SilentlyContinue) {
    try {
        $magickVersion = (magick --version 2>&1) | Select-Object -First 1
        if ($magickVersion -and $magickVersion -match "ImageMagick|Version:") {
            Write-Success "ImageMagick found (magick command)"
            Write-Output "  Version: $magickVersion"
            $magickFound = $true
            $hasAnyConverter = $true
        }
    } catch {}
}

# Check for 'convert' command, but verify it's ImageMagick, not Windows convert
if (-not $magickFound) {
    if (Get-Command convert -ErrorAction SilentlyContinue) {
        try {
            # Windows has a built-in 'convert' command, so we need to verify it's ImageMagick
            # ImageMagick's convert will show version info, Windows convert will show help for disk conversion
            $convertOutput = (convert --version 2>&1) | Out-String
            if ($convertOutput -match "ImageMagick|Version:") {
                Write-Success "ImageMagick found (convert command)"
                Write-Output "  Version: $($convertOutput -split "`n" | Select-Object -First 1)"
                $magickFound = $true
                $hasAnyConverter = $true
            } else {
                # This is Windows' built-in convert command, not ImageMagick
                Write-Info "ImageMagick not found (Windows convert command detected, not ImageMagick)"
            }
        } catch {
            # If we can't determine, assume it's not ImageMagick
            Write-Info "ImageMagick not found"
        }
    } else {
        Write-Info "ImageMagick not found (optional)"
    }
}
Write-Output ""

# Check for pdfunite (Alternative PDF Combiner)
Write-Info "Checking for pdfunite (alternative PDF combiner)..."
$pdfuniteFound = $false
if (Get-Command pdfunite -ErrorAction SilentlyContinue) {
    try {
        $pdfuniteVersion = (pdfunite --version 2>&1) | Select-Object -First 1
        if ($pdfuniteVersion -and $pdfuniteVersion -notmatch "error|not found") {
            Write-Success "pdfunite found"
            Write-Output "  Version: $pdfuniteVersion"
            $pdfuniteFound = $true
            $hasAnyCombiner = $true
        }
    } catch {
        try {
            $testResult = (pdfunite --version 2>&1)
            if ($LASTEXITCODE -eq 0 -or $testResult) {
                Write-Success "pdfunite found"
                $pdfuniteFound = $true
                $hasAnyCombiner = $true
            }
        } catch {}
    }
}

if (-not $pdfuniteFound) {
    Write-Info "pdfunite not found (optional)"
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

# Check PDF export capability
if ($hasRecommendedConverter -and $hasRecommendedCombiner) {
    Write-Success "Recommended tools for PDF export are installed"
    Write-Output "  Full PDF export functionality available"
} elseif ($hasAnyConverter -and $hasAnyCombiner) {
    Write-Warning "Alternative tools for PDF export are installed"
    Write-Output "  PDF export functionality available (but recommended tools not found)"
} else {
    Write-Warning "PDF export tools are missing"
    if (-not $hasAnyConverter) {
        Write-Output "  • Missing SVG converter"
    }
    if (-not $hasAnyCombiner) {
        Write-Output "  • Missing PDF combiner"
    }
    Write-Output ""
    Write-Output "  Plugin will work without these, but PDF export will be unavailable"
}
Write-Output ""

#============================================
# Installation Recommendations
#============================================
if (-not $hasRecommendedConverter -or -not $hasRecommendedCombiner) {
    Write-Header "RECOMMENDED INSTALLATION"
    Write-Header "--------------------------------------------"
    Write-Output ""
    Write-ColorOutput Green "This combination works well:"
    Write-Output ""
    
    if (-not $hasRecommendedConverter) {
        Write-ColorOutput Cyan "1. console-rsvg-convert (SVG Converter):"
        Write-Output "   • Download: https://github.com/miyako/console-rsvg-convert/releases"
        Write-Output "   • Copy the single .exe file to a directory in PATH"
        Write-Output "   • Option A: Copy to C:\Windows\ (already in PATH)"
        Write-Output "   • Option B: Copy to C:\Tools\ and add to PATH"
        Write-Output ""
    }
    
    if (-not $hasRecommendedCombiner) {
        Write-ColorOutput Cyan "2. PDFtk (PDF Combiner):"
        Write-Output "   • Download: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/"
        Write-Output "   • Install PDFtk Free (includes command-line tool)"
        Write-Output "   • Installer will add to PATH automatically"
        Write-Output ""
    }
    
    Write-ColorOutput Yellow "Alternative tools are also supported (see requirements.md)"
    Write-Output ""
}

#============================================
# Next Steps
#============================================
Write-Header "NEXT STEPS"
Write-Header "--------------------------------------------"
Write-Output ""

if ($allRequired) {
    Write-Output "  1. Install recommended tools (if desired for PDF export)"
    Write-Output "  2. Run install.ps1 to install PacketReporter plugin"
    Write-Output "  3. Restart Wireshark"
    Write-Output "  4. Access plugin via: Tools -> PacketReporter"
} else {
    Write-Output "  1. Install missing required dependencies (Wireshark)"
    Write-Output "  2. Run this script again to verify installation"
    Write-Output "  3. Install recommended tools (if desired for PDF export)"
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

Write-Header "============================================"
Write-Output ""

# Exit code based on required dependencies
if ($allRequired) {
    exit 0
} else {
    exit 1
}
