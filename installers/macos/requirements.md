# macOS Requirements - PacketReporter

This document outlines all prerequisites and dependencies for installing and running PacketReporter on macOS.

## System Requirements

- **Operating System**: macOS 10.14 (Mojave) or later
- **Architecture**: Intel (x86_64) or Apple Silicon (ARM64)

## Required Dependencies

### 1. Wireshark

**Minimum Version**: 4.0 or later  
**Purpose**: Network protocol analyzer that hosts the Lua plugin

**Installation**:
```bash
# Download from official website
open https://www.wireshark.org/download.html

# Or via Homebrew
brew install --cask wireshark
```

**Verification**:
```bash
# Check if installed
ls /Applications/Wireshark.app

# Check version
/Applications/Wireshark.app/Contents/MacOS/Wireshark --version
```

**Expected Output**: `Wireshark 4.x.x`

### 2. Lua

**Minimum Version**: Lua 5.2 or later  
**Purpose**: Scripting engine for the plugin

**Note**: Lua is bundled with Wireshark - no separate installation needed.

**Verification**:
```bash
# Check Lua availability in Wireshark
/Applications/Wireshark.app/Contents/MacOS/Wireshark -X lua_script:print_version.lua
```

## Optional Dependencies (PDF Export)

For full PDF export functionality, at least one converter and one combiner are required.

### PDF Converters (Choose One)

#### Option 1: librsvg (Recommended)

**Purpose**: Converts SVG charts to PNG/PDF  
**Performance**: Fastest

**Installation**:
```bash
brew install librsvg
```

**Verification**:
```bash
rsvg-convert --version
```

**Typical Location**: 
- Intel: `/usr/local/bin/rsvg-convert`
- Apple Silicon: `/opt/homebrew/bin/rsvg-convert`

#### Option 2: Inkscape

**Purpose**: Alternative SVG converter  
**Performance**: Slower but more features

**Installation**:
```bash
brew install --cask inkscape
```

**Verification**:
```bash
inkscape --version
# Or check app
ls /Applications/Inkscape.app
```

#### Option 3: ImageMagick

**Purpose**: Image manipulation toolkit  
**Performance**: Moderate

**Installation**:
```bash
brew install imagemagick
```

**Verification**:
```bash
magick --version
# Or legacy command
convert --version
```

### PDF Combiners (Choose One)

#### Option 1: pdfunite (Recommended)

**Purpose**: Combines multiple PDF pages  
**Part of**: Poppler utilities

**Installation**:
```bash
brew install poppler
```

**Verification**:
```bash
pdfunite --version
```

#### Option 2: pdftk

**Purpose**: PDF toolkit for manipulation  
**Note**: Requires Rosetta on Apple Silicon

**Installation**:
```bash
brew install pdftk-java
```

**Verification**:
```bash
pdftk --version
```

## Quick Install All Dependencies

**Complete Installation** (recommended):
```bash
# Install Wireshark
brew install --cask wireshark

# Install PDF dependencies
brew install librsvg poppler
```

## Plugin Directory

**Location**: `~/.local/lib/wireshark/plugin/`

**Note**: This is specified in your user rules. The installer will automatically create this directory if it doesn't exist.

**Alternative Locations** (not used by this installer):
- `~/.local/lib/wireshark/plugins/` (with 's')
- `~/.config/wireshark/plugins/`

## Homebrew

**Purpose**: Package manager for macOS (optional but highly recommended)

**Installation**:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Verification**:
```bash
brew --version
```

## Permission Requirements

- **Read/Write**: `~/.local/lib/wireshark/plugin/` directory
- **Read**: Installation directory for the plugin file
- **Write**: `~/Documents/PacketReporter Reports/` for generated reports

## Verification Checklist

Use this checklist to verify your installation:

```bash
# 1. Check Wireshark
[ -d /Applications/Wireshark.app ] && echo "✓ Wireshark installed" || echo "✗ Wireshark missing"

# 2. Check Homebrew
command -v brew &>/dev/null && echo "✓ Homebrew installed" || echo "⚠ Homebrew not found"

# 3. Check SVG converter (at least one needed)
command -v rsvg-convert &>/dev/null && echo "✓ librsvg installed" || echo "✗ librsvg missing"
command -v inkscape &>/dev/null && echo "✓ Inkscape installed" || echo "✗ Inkscape missing"
command -v magick &>/dev/null && echo "✓ ImageMagick installed" || echo "✗ ImageMagick missing"

# 4. Check PDF combiner (at least one needed)
command -v pdfunite &>/dev/null && echo "✓ pdfunite installed" || echo "✗ pdfunite missing"
command -v pdftk &>/dev/null && echo "✓ pdftk installed" || echo "✗ pdftk missing"

# 5. Check plugin directory
[ -d ~/.local/lib/wireshark/plugin ] && echo "✓ Plugin directory exists" || echo "⚠ Plugin directory not created yet"
```

## Troubleshooting

### Wireshark Not Found
```bash
# Check installation
ls /Applications/ | grep -i wireshark

# If not found, reinstall
brew install --cask wireshark
```

### Homebrew Command Not Found
```bash
# Check if Homebrew is in PATH
echo $PATH | grep -o homebrew

# Add to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc

# Add to PATH (Intel)
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### PDF Export Not Working
```bash
# Install recommended dependencies
brew install librsvg poppler

# Verify installation
which rsvg-convert pdfunite
```

### Permission Denied
```bash
# Fix plugin directory permissions
mkdir -p ~/.local/lib/wireshark/plugin
chmod 755 ~/.local/lib/wireshark/plugin
```

## Architecture-Specific Notes

### Apple Silicon (M1/M2/M3)

- Homebrew installs to: `/opt/homebrew/`
- Some tools may require Rosetta 2:
  ```bash
  softwareupdate --install-rosetta
  ```

### Intel Macs

- Homebrew installs to: `/usr/local/`
- No special considerations needed

## Additional Resources

- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [Homebrew Documentation](https://docs.brew.sh/)
- [Wireshark Lua API Reference](https://www.wireshark.org/docs/wsdg_html_chunked/wsluarm.html)

## Minimum Installation

If you only want to run the plugin without PDF export:

```bash
# Only Wireshark is required
brew install --cask wireshark
```

**Note**: Reports will still generate HTML output viewable in browser, but PDF export will be unavailable.

## Recommended Installation

For full functionality including PDF export:

```bash
# Complete setup
brew install --cask wireshark
brew install librsvg poppler
```

This provides optimal performance and all features.
