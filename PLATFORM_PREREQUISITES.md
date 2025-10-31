# Platform Prerequisites for PacketReporter

This document provides a comprehensive overview of the prerequisites required for each platform (macOS, Linux, Windows) to handle SVG and PDF files in PacketReporter.

## Overview

PacketReporter generates network analysis reports with visualizations in SVG format and exports them to multi-page PDF documents. This process requires:

1. **SVG Converter** - Converts SVG charts to rasterized or PDF format
2. **PDF Combiner** - Merges multiple PDF pages into a single document

## Prerequisites by Platform

### macOS

#### System Requirements
- **OS**: macOS 10.14 (Mojave) or later
- **Architecture**: Intel (x86_64) or Apple Silicon (ARM64)

#### Required Dependencies
- **Wireshark 4.0+** (includes Lua 5.2+)
  ```bash
  brew install --cask wireshark
  ```

#### Optional Dependencies (for PDF Export)

**SVG Converters (Choose at least one):**

1. **librsvg** (Recommended - Fastest)
   ```bash
   brew install librsvg
   ```
   - Command: `rsvg-convert`
   - Intel path: `/usr/local/bin/rsvg-convert`
   - Apple Silicon path: `/opt/homebrew/bin/rsvg-convert`
   - Performance: Fastest option
   - Converts: SVG → PNG/PDF

2. **Inkscape** (Feature-rich alternative)
   ```bash
   brew install --cask inkscape
   ```
   - Command: `inkscape`
   - Location: `/Applications/Inkscape.app`
   - Performance: Slower but more features
   - Converts: SVG → PDF/PNG

3. **ImageMagick** (Moderate performance)
   ```bash
   brew install imagemagick
   ```
   - Command: `magick` or `convert`
   - Performance: Moderate
   - Converts: SVG → various formats

**PDF Combiners (Choose at least one):**

1. **pdfunite** (Recommended)
   ```bash
   brew install poppler
   ```
   - Command: `pdfunite`
   - Part of: Poppler utilities
   - Purpose: Combines multiple PDF pages

2. **pdftk** (Alternative)
   ```bash
   brew install pdftk-java
   ```
   - Command: `pdftk`
   - Note: Requires Rosetta on Apple Silicon
   - Purpose: PDF manipulation toolkit

**Complete Installation:**
```bash
brew install --cask wireshark
brew install librsvg poppler
```

---

### Linux

#### System Requirements
- **OS**: Any modern Linux distribution
- **Architecture**: x86_64 (AMD64) or ARM64
- **Kernel**: Linux 3.10 or later

#### Supported Distributions
- Debian 10+ / Ubuntu 18.04+
- Fedora 30+ / RHEL 8+ / CentOS 8+
- Arch Linux
- openSUSE Leap 15+

#### Required Dependencies
- **Wireshark 4.0+** (includes Lua 5.2+)

  **Debian/Ubuntu:**
  ```bash
  sudo apt install wireshark
  sudo usermod -aG wireshark $USER
  ```

  **Fedora:**
  ```bash
  sudo dnf install wireshark
  sudo usermod -aG wireshark $USER
  ```

  **Arch:**
  ```bash
  sudo pacman -S wireshark-qt
  sudo usermod -aG wireshark $USER
  ```

  **Important**: Log out and back in after adding user to wireshark group!

#### Optional Dependencies (for PDF Export)

**SVG Converters (Choose at least one):**

1. **librsvg** (Recommended - Fastest)
   
   **Debian/Ubuntu:**
   ```bash
   sudo apt install librsvg2-bin
   ```
   
   **Fedora:**
   ```bash
   sudo dnf install librsvg2-tools
   ```
   
   **Arch:**
   ```bash
   sudo pacman -S librsvg
   ```
   
   - Command: `rsvg-convert`
   - Performance: Fastest
   - Converts: SVG → PNG/PDF

2. **Inkscape** (Feature-rich alternative)
   
   **Debian/Ubuntu:**
   ```bash
   sudo apt install inkscape
   ```
   
   **Fedora:**
   ```bash
   sudo dnf install inkscape
   ```
   
   - Command: `inkscape`
   - Performance: Slower but feature-rich
   - Converts: SVG → PDF/PNG

3. **ImageMagick** (Moderate performance)
   
   **Debian/Ubuntu:**
   ```bash
   sudo apt install imagemagick
   ```
   
   **Fedora:**
   ```bash
   sudo dnf install ImageMagick
   ```
   
   - Command: `magick` or `convert`
   - Performance: Moderate
   - Converts: SVG → various formats

**PDF Combiners (Choose at least one):**

1. **pdfunite** (Recommended)
   
   **Debian/Ubuntu:**
   ```bash
   sudo apt install poppler-utils
   ```
   
   **Fedora:**
   ```bash
   sudo dnf install poppler-utils
   ```
   
   **Arch:**
   ```bash
   sudo pacman -S poppler
   ```
   
   - Command: `pdfunite`
   - Part of: Poppler utilities
   - Purpose: Combines PDF pages

2. **pdftk** (Alternative)
   
   **Debian/Ubuntu:**
   ```bash
   sudo apt install pdftk  # or pdftk-java for newer versions
   ```
   
   **Fedora:**
   ```bash
   sudo dnf install pdftk
   ```
   
   - Command: `pdftk`
   - Purpose: PDF manipulation toolkit

**Complete Installation:**

**Debian/Ubuntu:**
```bash
sudo apt install wireshark librsvg2-bin poppler-utils
sudo usermod -aG wireshark $USER
```

**Fedora:**
```bash
sudo dnf install wireshark librsvg2-tools poppler-utils
sudo usermod -aG wireshark $USER
```

---

### Windows

#### System Requirements
- **OS**: Windows 10 or later (Windows Server 2016+ also supported)
- **Architecture**: x64 (64-bit) or x86 (32-bit)
- **Privileges**: Standard user (Administrator for system-wide installation)

#### Required Dependencies

1. **Wireshark 4.0+** (includes Lua 5.2+)
   - Download: [wireshark.org](https://www.wireshark.org/download.html)
   - Install with Npcap for packet capture
   - Typical location: `C:\Program Files\Wireshark\`

2. **Npcap** (Packet capture driver)
   - Included with Wireshark installer
   - Supports Windows 10/11 loopback capture
   - Verification: `Get-Service npcap`

#### Optional Dependencies (for PDF Export)

**SVG Converters (Choose at least one):**

1. **librsvg (rsvg-convert)** (Recommended - Fastest)
   
   **Via Chocolatey:**
   ```powershell
   choco install rsvg-convert
   ```
   
   **Manual:**
   - Download: [GitHub Release](https://github.com/miyako/console-rsvg-convert/releases)
   - Extract to folder (e.g., `C:\Tools\rsvg\`)
   - Add to PATH
   
   - Command: `rsvg-convert`
   - Performance: Fastest
   - Converts: SVG → PNG/PDF

2. **Inkscape** (Feature-rich alternative)
   
   **Via Chocolatey:**
   ```powershell
   choco install inkscape
   ```
   
   **Manual:**
   - Download: [inkscape.org](https://inkscape.org/release/)
   - Run installer (adds to PATH automatically)
   - Location: `C:\Program Files\Inkscape\bin\inkscape.exe`
   
   - Command: `inkscape`
   - Performance: Slower but feature-rich
   - Converts: SVG → PDF/PNG

3. **ImageMagick** (Moderate performance)
   
   **Via Chocolatey:**
   ```powershell
   choco install imagemagick
   ```
   
   **Manual:**
   - Download: [imagemagick.org](https://imagemagick.org/script/download.php#windows)
   - Check "Add to system PATH" during installation
   
   - Command: `magick` or `convert`
   - Performance: Moderate
   - Converts: SVG → various formats

**PDF Combiners (Choose at least one):**

1. **pdfunite** (Recommended)
   
   **Via Chocolatey:**
   ```powershell
   choco install poppler
   ```
   
   **Manual:**
   - Download: [GitHub Release](https://github.com/oschwartz10612/poppler-windows/releases)
   - Extract to folder (e.g., `C:\Tools\poppler\`)
   - Add `Library\bin` subfolder to PATH
   
   - Command: `pdfunite`
   - Part of: Poppler utilities
   - Purpose: Combines PDF pages

2. **pdftk** (Alternative)
   
   **Via Chocolatey:**
   ```powershell
   choco install pdftk
   ```
   
   **Manual:**
   - Download: [pdflabs.com](https://www.pdflabs.com/tools/pdftk-the-pdf-toolkit/)
   - Run installer
   
   - Command: `pdftk`
   - Purpose: PDF manipulation toolkit

#### Chocolatey Package Manager (Recommended)

**Installation:**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Complete Installation via Chocolatey:**
```powershell
choco install wireshark rsvg-convert poppler
```

---

## Dependency Matrix

| Platform | SVG Converter (Recommended) | PDF Combiner (Recommended) | Package Manager |
|----------|----------------------------|---------------------------|-----------------|
| **macOS** | librsvg (`rsvg-convert`) | poppler (`pdfunite`) | Homebrew |
| **Linux** | librsvg2-bin (`rsvg-convert`) | poppler-utils (`pdfunite`) | apt/dnf/pacman |
| **Windows** | rsvg-convert | poppler (`pdfunite`) | Chocolatey |

## SVG to PDF Conversion Process

### Step 1: SVG Generation
- PacketReporter generates SVG files for all visualizations:
  - Bar charts (IP addresses, ports, DNS, HTTP)
  - Pie charts (protocol distribution, status codes)
  - Circular diagrams (communication matrix)
- SVG files are saved to: `~/Documents/PacketReporter Reports/`

### Step 2: SVG → PDF Conversion
Each SVG file is converted to an individual PDF page using one of:

1. **rsvg-convert** (Recommended)
   ```bash
   rsvg-convert -f pdf -o output.pdf input.svg
   ```

2. **inkscape**
   ```bash
   inkscape input.svg --export-pdf=output.pdf
   ```

3. **ImageMagick**
   ```bash
   magick convert input.svg output.pdf
   ```

### Step 3: PDF Page Combination
All individual PDF pages are merged into a single multi-page document using:

1. **pdfunite** (Recommended)
   ```bash
   pdfunite page1.pdf page2.pdf page3.pdf final-report.pdf
   ```

2. **pdftk**
   ```bash
   pdftk page1.pdf page2.pdf page3.pdf cat output final-report.pdf
   ```

## Performance Comparison

| Tool | Speed | Quality | Features | Recommendation |
|------|-------|---------|----------|----------------|
| **rsvg-convert** | ⚡⚡⚡ Fastest | High | Basic | Best for production |
| **Inkscape** | 🐢 Slowest | Highest | Advanced | Best for quality |
| **ImageMagick** | ⚡⚡ Moderate | Good | Versatile | Good compromise |

| Tool | Speed | Purpose | Recommendation |
|------|-------|---------|----------------|
| **pdfunite** | ⚡⚡⚡ Fastest | Simple merge | Best for production |
| **pdftk** | ⚡⚡ Good | Advanced manipulation | Alternative option |

## Verification Commands

### macOS/Linux
```bash
# Check SVG converters
command -v rsvg-convert && echo "✓ librsvg" || echo "✗ librsvg"
command -v inkscape && echo "✓ Inkscape" || echo "✗ Inkscape"
command -v magick && echo "✓ ImageMagick" || echo "✗ ImageMagick"

# Check PDF combiners
command -v pdfunite && echo "✓ pdfunite" || echo "✗ pdfunite"
command -v pdftk && echo "✓ pdftk" || echo "✗ pdftk"
```

### Windows (PowerShell)
```powershell
# Check SVG converters
Get-Command rsvg-convert -ErrorAction SilentlyContinue
Get-Command inkscape -ErrorAction SilentlyContinue
Get-Command magick -ErrorAction SilentlyContinue

# Check PDF combiners
Get-Command pdfunite -ErrorAction SilentlyContinue
Get-Command pdftk -ErrorAction SilentlyContinue
```

## Troubleshooting

### "PDF export not available" Message

**Cause**: No SVG converter or PDF combiner found in system PATH.

**Solution**:
- **macOS**: `brew install librsvg poppler`
- **Linux**: `sudo apt install librsvg2-bin poppler-utils` (Debian/Ubuntu)
- **Windows**: `choco install rsvg-convert poppler`

### Command Not Found

**Cause**: Tools not in system PATH.

**Solution**:
- Verify installation: `which rsvg-convert` (macOS/Linux) or `Get-Command rsvg-convert` (Windows)
- Add to PATH if necessary
- Restart terminal/PowerShell after installation

### Conversion Failures

**Cause**: Corrupt SVG or insufficient permissions.

**Solution**:
- Check SVG file validity
- Verify write permissions to output directory
- Try alternative converter

## Minimum vs. Recommended Installation

### Minimum Installation (No PDF Export)
- **Wireshark 4.0+** only
- Reports viewable as HTML in browser
- SVG files available separately
- No PDF generation capability

### Recommended Installation (Full Features)
- **Wireshark 4.0+**
- **librsvg** (or alternative SVG converter)
- **poppler** (pdfunite) (or alternative PDF combiner)
- Full PDF export functionality
- Optimal performance

## Plugin Directories by Platform

| Platform | Directory |
|----------|-----------|
| **macOS** | `~/.local/lib/wireshark/plugin/` |
| **Linux** | `~/.local/lib/wireshark/plugin/` |
| **Windows** | `%APPDATA%\Wireshark\plugins\` |

## Report Output Directory

All platforms: `~/Documents/PacketReporter Reports/` (or `%USERPROFILE%\Documents\PacketReporter Reports\` on Windows)

## Additional Resources

- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [librsvg Project](https://wiki.gnome.org/Projects/LibRsvg)
- [Poppler Project](https://poppler.freedesktop.org/)
- [Inkscape Documentation](https://inkscape.org/doc/)
- [ImageMagick Documentation](https://imagemagick.org/index.php)

## Summary

**For SVG and PDF handling, each platform requires:**

1. **At least one SVG converter** (librsvg recommended for best performance)
2. **At least one PDF combiner** (pdfunite recommended for best performance)

**Recommended quick setup:**
- **macOS**: `brew install librsvg poppler`
- **Linux**: `sudo apt install librsvg2-bin poppler-utils` (Debian/Ubuntu)
- **Windows**: `choco install rsvg-convert poppler`

These tools enable PacketReporter to convert SVG visualizations to PDF format and combine multiple pages into a comprehensive network analysis report.
