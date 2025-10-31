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

## Optional Dependencies (PDF Export)

For full PDF export functionality, at least one converter and one combiner are required.

### PDF Converters (Choose One)

#### Option 1: librsvg (Recommended)

**Purpose**: Converts SVG charts to PNG/PDF  
**Performance**: Fastest

**Installation via Chocolatey**:
```powershell
# Install Chocolatey first if not installed
# See: https://chocolatey.org/install

# Install rsvg-convert
choco install rsvg-convert
```

**Manual Installation**:
1. Download from [GitHub Release](https://github.com/miyako/console-rsvg-convert/releases)
2. Extract to a folder (e.g., `C:\Tools\rsvg\`)
3. Add to PATH:
   ```powershell
   $env:Path += ";C:\Tools\rsvg"
   # Make permanent via System Properties → Environment Variables
   ```

**Verification**:
```powershell
rsvg-convert --version
```

#### Option 2: Inkscape

**Purpose**: Alternative SVG converter  
**Performance**: Slower but feature-rich

**Installation via Chocolatey**:
```powershell
choco install inkscape
```

**Manual Installation**:
1. Download from [inkscape.org](https://inkscape.org/release/)
2. Run installer
3. Accept defaults (adds to PATH automatically)

**Typical Location**: `C:\Program Files\Inkscape\bin\inkscape.exe`

**Verification**:
```powershell
inkscape --version
```

#### Option 3: ImageMagick

**Purpose**: Image manipulation toolkit  
**Performance**: Moderate

**Installation via Chocolatey**:
```powershell
choco install imagemagick
```

**Manual Installation**:
1. Download from [imagemagick.org](https://imagemagick.org/script/download.php#windows)
2. Run installer
3. Check "Add to system PATH" during installation

**Verification**:
```powershell
magick --version
# Or legacy command
convert --version
```

### PDF Combiners (Choose One)

#### Option 1: pdfunite (Recommended)

**Purpose**: Combines multiple PDF pages  
**Part of**: Poppler utilities

**Installation via Chocolatey**:
```powershell
choco install poppler
```

**Manual Installation**:
1. Download from [GitHub Release](https://github.com/oschwartz10612/poppler-windows/releases)
2. Extract to a folder (e.g., `C:\Tools\poppler\`)
3. Add `Library\bin` subfolder to PATH:
   ```powershell
   $env:Path += ";C:\Tools\poppler\Library\bin"
   ```

**Verification**:
```powershell
pdfunite --version
```

#### Option 2: pdftk

**Purpose**: PDF toolkit for manipulation

**Installation via Chocolatey**:
```powershell
choco install pdftk
```

**Manual Installation**:
1. Download from [pdflabs.com](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)
2. Run installer
3. Add to PATH if not automatic

**Verification**:
```powershell
pdftk --version
```

## Chocolatey Package Manager

**Purpose**: Simplifies installation of PDF dependencies (highly recommended)

**Installation**:

1. Open PowerShell as Administrator
2. Run:
   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force
   [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
   iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
   ```
3. Restart PowerShell

**Verification**:
```powershell
choco --version
```

**Website**: [chocolatey.org](https://chocolatey.org/install)

## Quick Install Commands

### Using Chocolatey (Recommended)

```powershell
# Install Wireshark
choco install wireshark

# Install PDF dependencies
choco install rsvg-convert poppler

# Or install everything at once
choco install wireshark rsvg-convert poppler
```

### Manual Installation

1. Install [Wireshark](https://www.wireshark.org/download.html)
2. Install [rsvg-convert](https://github.com/miyako/console-rsvg-convert/releases)
3. Install [Poppler](https://github.com/oschwartz10612/poppler-windows/releases)
4. Add tools to PATH via System Properties → Environment Variables

## Plugin Directory

**Location**: `%APPDATA%\Wireshark\plugins\`

**Full Path Example**: `C:\Users\YourUsername\AppData\Roaming\Wireshark\plugins\`

**Note**: The installer will automatically create this directory.

**Alternative Locations** (not used by default):
- `%PROGRAMFILES%\Wireshark\plugins\` (system-wide, requires admin)
- `%WIRESHARK_PLUGIN_DIR%` (if environment variable is set)

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

# 3. Check Chocolatey
Write-Host ""
Write-Host "Checking Chocolatey..." -ForegroundColor Yellow
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "✓ Chocolatey installed" -ForegroundColor Green
} else {
    Write-Host "⚠ Chocolatey not found (optional)" -ForegroundColor Yellow
}

# 4. Check SVG converters
Write-Host ""
Write-Host "Checking SVG Converters..." -ForegroundColor Yellow
$hasConverter = $false
if (Get-Command rsvg-convert -ErrorAction SilentlyContinue) {
    Write-Host "✓ rsvg-convert found" -ForegroundColor Green
    $hasConverter = $true
} else {
    Write-Host "✗ rsvg-convert not found" -ForegroundColor Red
}

if (Test-Path "$env:ProgramFiles\Inkscape\bin\inkscape.exe") {
    Write-Host "✓ Inkscape found" -ForegroundColor Green
    $hasConverter = $true
} else {
    Write-Host "✗ Inkscape not found" -ForegroundColor Red
}

if (Get-Command magick -ErrorAction SilentlyContinue) {
    Write-Host "✓ ImageMagick found" -ForegroundColor Green
    $hasConverter = $true
} else {
    Write-Host "✗ ImageMagick not found" -ForegroundColor Red
}

# 5. Check PDF combiners
Write-Host ""
Write-Host "Checking PDF Combiners..." -ForegroundColor Yellow
$hasCombiner = $false
if (Get-Command pdfunite -ErrorAction SilentlyContinue) {
    Write-Host "✓ pdfunite found" -ForegroundColor Green
    $hasCombiner = $true
} else {
    Write-Host "✗ pdfunite not found" -ForegroundColor Red
}

if (Get-Command pdftk -ErrorAction SilentlyContinue) {
    Write-Host "✓ pdftk found" -ForegroundColor Green
    $hasCombiner = $true
} else {
    Write-Host "✗ pdftk not found" -ForegroundColor Red
}

# 6. Check plugin directory
Write-Host ""
Write-Host "Checking Plugin Directory..." -ForegroundColor Yellow
if (Test-Path "$env:APPDATA\Wireshark\plugins") {
    Write-Host "✓ Plugin directory exists" -ForegroundColor Green
} else {
    Write-Host "⚠ Plugin directory not created yet" -ForegroundColor Yellow
}

Write-Host ""
```

Save as `check-prereqs.ps1` and run with:
```powershell
powershell -ExecutionPolicy Bypass -File check-prereqs.ps1
```

## Troubleshooting

### Wireshark Not Found

```powershell
# Check if installed
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | 
  Where-Object { $_.DisplayName -like "*Wireshark*" }

# Reinstall if needed
choco install wireshark --force
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
4. Add new entry (e.g., `C:\Tools\rsvg`)
5. Click OK and restart PowerShell

**Or via PowerShell (requires restart)**:
```powershell
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Tools\rsvg",
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

```powershell
# Install dependencies via Chocolatey
choco install rsvg-convert poppler

# Or manually download and add to PATH
# rsvg: https://github.com/miyako/console-rsvg-convert/releases
# poppler: https://github.com/oschwartz10612/poppler-windows/releases
```

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
2. Or via Chocolatey:
   ```powershell
   choco install vcredist-all
   ```

## Windows-Specific Notes

### Windows 10/11
- Full support
- Npcap required (WinPcap deprecated)
- Windows Defender may prompt - allow Wireshark

### Windows Server
- Supported on Server 2016+
- May need to manually install .NET Framework
- Consider firewall rules for capture

### Antivirus Software
Some antivirus programs may flag Wireshark or packet capture:
- Add Wireshark to exceptions
- Allow network capture prompts
- Whitelist plugin directory

## Additional Resources

- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [Wireshark Wiki - Windows](https://wiki.wireshark.org/CaptureSetup/Platforms/Windows)
- [Npcap Documentation](https://npcap.com/guide/)
- [Chocolatey Packages](https://community.chocolatey.org/packages)

## Minimum Installation

If you only want to run the plugin without PDF export:

```powershell
# Via Chocolatey
choco install wireshark

# Or manual download from wireshark.org
```

**Note**: Reports will still generate HTML output viewable in browser, but PDF export will be unavailable.

## Recommended Installation

For full functionality including PDF export:

```powershell
# Install Chocolatey first (see Chocolatey section above)

# Then install all dependencies
choco install wireshark rsvg-convert poppler

# Restart PowerShell after installation
```

This provides optimal performance and all features.

## Uninstallation

To uninstall the plugin:

```powershell
# Remove plugin file
Remove-Item "$env:APPDATA\Wireshark\plugins\packet_reporter.lua"

# Optionally remove dependencies
choco uninstall rsvg-convert poppler

# To uninstall Wireshark
choco uninstall wireshark
# Or use Windows Settings → Apps → Uninstall
```
