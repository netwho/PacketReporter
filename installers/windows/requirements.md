# Windows Requirements - PacketReporter

This document outlines all prerequisites and dependencies for installing and running PacketReporter on Windows.

## Quick Prerequisites Check

**Automated Check Script**: Before manually reviewing the requirements below, you can run our automated prerequisites check script:

```powershell
powershell -ExecutionPolicy Bypass -File check-prereqs.ps1
```

This script will:
- ✓ Check for all required dependencies (Wireshark, Npcap)
- ✓ Check for optional dependencies (SVG converters, PDF combiners)
- ✓ Detect installed versions
- ✓ Provide specific installation commands for missing dependencies
- ✓ Verify plugin directory status

**Location**: `installers/windows/check-prereqs.ps1`

---

## System Requirements

- **Operating System**: Windows 10 or later (Windows Server 2016+ also supported)
- **Architecture**: x64 (64-bit) or x86 (32-bit)
- **Privileges**: Standard user (Administrator for system-wide installation)

## Required Dependencies

### 1. Wireshark

**Minimum Version**: 4.0 or later  
**Purpose**: Network protocol analyzer that hosts the Lua plugin

**Installation**:

1. Download installer from [wireshark.org](https://www.wireshark.org/download.html)
2. Run the installer
3. During installation:
   - Accept default options
   - Include "Install WinPcap/Npcap" for packet capture
4. Complete installation and restart if prompted

**Download Links**:
- [Windows x64 Installer](https://www.wireshark.org/download.html)
- [Windows x86 (32-bit) Installer](https://www.wireshark.org/download.html)

**Typical Installation Locations**:
- `C:\Program Files\Wireshark\` (64-bit)
- `C:\Program Files (x86)\Wireshark\` (32-bit)

**Verification**:
```powershell
# Check if installed
Test-Path "C:\Program Files\Wireshark\Wireshark.exe"

# Check version
& "C:\Program Files\Wireshark\Wireshark.exe" --version
```

**Expected Output**: `Wireshark 4.x.x`

### 2. Lua

**Minimum Version**: Lua 5.2 or later  
**Purpose**: Scripting engine for the plugin

**Note**: Lua is bundled with Wireshark - no separate installation needed.

### 3. Packet Capture Driver

**Required**: Npcap (or legacy WinPcap)

**Npcap (Recommended)**:
- Included with Wireshark installer
- Supports Windows 10/11 loopback capture
- [Standalone installer](https://npcap.com/#download)

**WinPcap (Legacy)**:
- Older driver, not recommended for new installations
- May not work on Windows 10/11

**Verification**:
```powershell
# Check Npcap service
Get-Service npcap
```

## Recommended Tools (PDF Export)

For full PDF export functionality, the following combination works well:

### 1. console-rsvg-convert (Recommended)

**Purpose**: Converts SVG charts to PNG/PDF  
**Performance**: Fastest and most reliable

**Installation**:

1. Download from [GitHub Releases](https://github.com/miyako/console-rsvg-convert/releases)
2. Download the single executable file (e.g., `console-rsvg-convert.exe`)
3. Copy the executable to a directory that is in your system PATH:
   - **Option A**: Copy to `C:\Windows\` (system directory, already in PATH)
   - **Option B**: Create a custom directory (e.g., `C:\Tools\`) and add it to PATH:
     ```powershell
     # Create directory
     New-Item -ItemType Directory -Force -Path "C:\Tools"
     
     # Add to PATH (requires restart)
     [Environment]::SetEnvironmentVariable(
         "Path",
         [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Tools",
         "User"
     )
     ```
4. Copy `console-rsvg-convert.exe` to your chosen directory

**Verification**:
```powershell
rsvg-convert --version
```

**Note**: The installer script will create a `C:\Tools\` directory if it doesn't exist and can help set up the PATH.

### 2. PDFtk (Recommended)

**Purpose**: Combines multiple PDF pages into a single document

**Installation**:

1. Download from [PDF Labs](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)
2. Choose **PDFtk Free** (free version) or **PDFtk Pro** (paid, $3.99)
3. Run the installer
4. The installer will automatically add PDFtk to your PATH

**Verification**:
```powershell
pdftk --version
```

**Note**: PDFtk Free includes both the GUI and command-line tool (PDFtk Server).

## Alternative Tools

If you prefer different tools, the following alternatives are also supported:

### Alternative SVG Converters

- **Inkscape**: [inkscape.org](https://inkscape.org/release/) - Feature-rich but slower
- **ImageMagick**: [imagemagick.org](https://imagemagick.org/script/download.php#windows) - Moderate performance

### Alternative PDF Combiners

- **pdfunite** (Poppler): [GitHub Releases](https://github.com/oschwartz10612/poppler-windows/releases) - Part of Poppler utilities

## Quick Installation Guide

### Step 1: Install Wireshark (Required)

```powershell
# Download and install from:
# https://www.wireshark.org/download.html
```

### Step 2: Install Recommended Tools (Optional, for PDF Export)

**console-rsvg-convert**:
1. Download from: https://github.com/miyako/console-rsvg-convert/releases
2. Copy the single `.exe` file to `C:\Windows\` or a directory in your PATH

**PDFtk**:
1. Download from: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/
2. Run the installer (adds to PATH automatically)

### Step 3: Install PacketReporter Plugin

```powershell
cd installers\windows
powershell -ExecutionPolicy Bypass -File install.ps1
```

The installer will:
- Create the plugin directory
- Copy the plugin file
- Create configuration directory
- Copy default logo and description files

## Plugin Directory

**Location**: `%APPDATA%\Wireshark\plugins\`

**Full Path Example**: `C:\Users\YourUsername\AppData\Roaming\Wireshark\plugins\`

**Note**: The installer will automatically create this directory.

## Configuration Directory

**Location**: `%USERPROFILE%\.packet_reporter\`

**Full Path Example**: `C:\Users\YourUsername\.packet_reporter\`

**Files**:
- `Logo.png` - Your company/organization logo (copied by installer)
- `packet_reporter.txt` - Report description (3 lines max, copied by installer)

## Permission Requirements

- **Read/Write**: `%APPDATA%\Wireshark\plugins\` directory
- **Read**: Installation directory for the plugin file
- **Write**: `%USERPROFILE%\Documents\PacketReporter Reports\` for generated reports
- **Network Capture**: Administrator privileges (or Npcap configured for non-admin)

## Verification Checklist

Use this PowerShell script to verify your installation:

```powershell
Write-Host "=== PacketReporter Prerequisites Check ===" -ForegroundColor Cyan
Write-Host ""

# 1. Check Wireshark
Write-Host "Checking Wireshark..." -ForegroundColor Yellow
if (Test-Path "$env:ProgramFiles\Wireshark\Wireshark.exe") {
    Write-Host "✓ Wireshark installed (64-bit)" -ForegroundColor Green
} elseif (Test-Path "${env:ProgramFiles(x86)}\Wireshark\Wireshark.exe") {
    Write-Host "✓ Wireshark installed (32-bit)" -ForegroundColor Green
} else {
    Write-Host "✗ Wireshark not found" -ForegroundColor Red
}

# 2. Check Npcap
Write-Host ""
Write-Host "Checking Npcap..." -ForegroundColor Yellow
try {
    $npcap = Get-Service npcap -ErrorAction SilentlyContinue
    if ($npcap) {
        Write-Host "✓ Npcap service installed ($($npcap.Status))" -ForegroundColor Green
    } else {
        Write-Host "⚠ Npcap service not found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Unable to check Npcap" -ForegroundColor Yellow
}

# 3. Check console-rsvg-convert
Write-Host ""
Write-Host "Checking console-rsvg-convert..." -ForegroundColor Yellow
if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
    Write-Host "✓ rsvg-convert found" -ForegroundColor Green
} else {
    Write-Host "✗ rsvg-convert not found" -ForegroundColor Red
    Write-Host "  Download from: https://github.com/miyako/console-rsvg-convert/releases" -ForegroundColor Yellow
}

# 4. Check PDFtk
Write-Host ""
Write-Host "Checking PDFtk..." -ForegroundColor Yellow
if (Get-Command pdftk -ErrorAction SilentlyContinue) {
    Write-Host "✓ pdftk found" -ForegroundColor Green
} else {
    Write-Host "✗ pdftk not found" -ForegroundColor Red
    Write-Host "  Download from: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/" -ForegroundColor Yellow
}

# 5. Check plugin directory
Write-Host ""
Write-Host "Checking Plugin Directory..." -ForegroundColor Yellow
if (Test-Path "$env:APPDATA\Wireshark\plugins") {
    Write-Host "✓ Plugin directory exists" -ForegroundColor Green
} else {
    Write-Host "⚠ Plugin directory not created yet" -ForegroundColor Yellow
}

Write-Host ""
```

Or use the automated check script:
```powershell
powershell -ExecutionPolicy Bypass -File check-prereqs.ps1
```

## Troubleshooting

### Wireshark Not Found

```powershell
# Check if installed
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
  Where-Object { $_.DisplayName -like "*Wireshark*" }

# Download and install from:
# https://www.wireshark.org/download.html
```

### PowerShell Execution Policy

If scripts won't run:
```powershell
# Check current policy
Get-ExecutionPolicy

# Allow scripts (as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or bypass for one command
powershell -ExecutionPolicy Bypass -File install.ps1
```

### PATH Not Working

To add a directory to PATH permanently:

1. Open System Properties (Win+Pause/Break)
2. Advanced System Settings → Environment Variables
3. Under "User variables", select PATH → Edit
4. Add new entry (e.g., `C:\Tools`)
5. Click OK and restart PowerShell

**Or via PowerShell (requires restart)**:
```powershell
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Tools",
    "User"
)
```

### Npcap Issues

```powershell
# Reinstall Npcap
# Download from https://npcap.com

# Check if service is running
Get-Service npcap | Start-Service

# Verify adapter
Get-NetAdapter | Where-Object { $_.DriverDescription -like "*Npcap*" }
```

### PDF Export Not Working

**Install recommended tools**:

1. **console-rsvg-convert**:
   - Download from: https://github.com/miyako/console-rsvg-convert/releases
   - Copy the single `.exe` file to `C:\Windows\` or add to PATH

2. **PDFtk**:
   - Download from: https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/
   - Run the installer

### Permission Denied

```powershell
# Fix plugin directory permissions
$pluginDir = "$env:APPDATA\Wireshark\plugins"
New-Item -ItemType Directory -Force -Path $pluginDir
icacls $pluginDir /grant "${env:USERNAME}:(OI)(CI)F" /T
```

### DLL Missing Errors

If you get DLL errors when running converters:

1. Install [Visual C++ Redistributables](https://aka.ms/vs/17/release/vc_redist.x64.exe)
2. Or download the static build of console-rsvg-convert from GitHub releases

## Windows-Specific Notes

### Windows 10/11
- Full support
- Npcap required (WinPcap deprecated)
- Windows Defender may prompt - allow Wireshark

### PDF Export Behavior
**Note**: During multi-page PDF export, you may briefly see command prompt windows flash on screen. This is normal behavior when external tools (rsvg-convert, pdftk) are being called. The windows will close automatically when processing completes.

### Windows Server
- Supported on Server 2016+
- May need to manually install .NET Framework
- Consider firewall rules for capture

### Antivirus Software
Some antivirus programs may flag Wireshark or packet capture:
- Add Wireshark to exceptions
- Allow network capture prompts
- Whitelist plugin directory

## Minimum Installation

If you only want to run the plugin without PDF export:

1. Install Wireshark from [wireshark.org](https://www.wireshark.org/download.html)
2. Run the installer script: `powershell -ExecutionPolicy Bypass -File install.ps1`

**Note**: Reports will still generate HTML output viewable in browser, but PDF export will be unavailable.

## Recommended Installation

For full functionality including PDF export:

1. **Install Wireshark** from [wireshark.org](https://www.wireshark.org/download.html)
2. **Install console-rsvg-convert**:
   - Download from: https://github.com/miyako/console-rsvg-convert/releases
   - Copy the single `.exe` file to `C:\Windows\` or a directory in PATH
3. **Install PDFtk** from [pdflabs.com](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)
4. **Run the installer**: `powershell -ExecutionPolicy Bypass -File install.ps1`

This provides optimal performance and all features.

## Uninstallation

To uninstall the plugin:

```powershell
# Remove plugin file
Remove-Item "$env:APPDATA\Wireshark\plugins\packet_reporter.lua"

# Optionally remove configuration directory
Remove-Item "$env:USERPROFILE\.packet_reporter" -Recurse -Force

# To uninstall Wireshark
# Use Windows Settings → Apps → Uninstall
```

## Additional Resources

- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [Wireshark Wiki - Windows](https://wiki.wireshark.org/CaptureSetup/Platforms/Windows)
- [Npcap Documentation](https://npcap.com/guide/)
- [console-rsvg-convert Releases](https://github.com/miyako/console-rsvg-convert/releases)
- [PDFtk - PDF Toolkit](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)
