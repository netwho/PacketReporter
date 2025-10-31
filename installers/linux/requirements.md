# Linux Requirements - PacketReporter

This document outlines all prerequisites and dependencies for installing and running PacketReporter on various Linux distributions.

## System Requirements

- **Operating System**: Any modern Linux distribution
- **Architecture**: x86_64 (AMD64) or ARM64
- **Kernel**: Linux 3.10 or later

## Supported Distributions

- Debian 10+ / Ubuntu 18.04+
- Fedora 30+ / RHEL 8+ / CentOS 8+
- Arch Linux
- openSUSE Leap 15+
- Other distributions with Wireshark 4.0+ available

## Required Dependencies

### 1. Wireshark

**Minimum Version**: 4.0 or later  
**Purpose**: Network protocol analyzer that hosts the Lua plugin

#### Debian / Ubuntu
```bash
sudo apt update
sudo apt install wireshark
```

#### Fedora
```bash
sudo dnf install wireshark
```

#### RHEL / CentOS
```bash
sudo yum install wireshark
```

#### Arch Linux
```bash
sudo pacman -S wireshark-qt
```

#### openSUSE
```bash
sudo zypper install wireshark
```

**Verification**:
```bash
# Check if installed
command -v wireshark

# Check version
wireshark --version
```

**Expected Output**: `Wireshark 4.x.x`

#### User Permissions

On most Linux distributions, you need to add your user to the `wireshark` group to capture packets:

```bash
# Add user to wireshark group
sudo usermod -aG wireshark $USER

# Or for some distributions
sudo usermod -aG pcap $USER

# Log out and back in for changes to take effect
```

### 2. Lua

**Minimum Version**: Lua 5.2 or later  
**Purpose**: Scripting engine for the plugin

**Note**: Lua is typically bundled with Wireshark - no separate installation needed.

**Optional - Standalone Lua** (if needed for testing):
```bash
# Debian/Ubuntu
sudo apt install lua5.2

# Fedora
sudo dnf install lua

# Arch Linux
sudo pacman -S lua

# openSUSE
sudo zypper install lua
```

## Optional Dependencies (PDF Export)

For full PDF export functionality, at least one converter and one combiner are required.

### PDF Converters (Choose One)

#### Option 1: librsvg (Recommended)

**Purpose**: Converts SVG charts to PNG/PDF  
**Performance**: Fastest

**Installation**:

**Debian/Ubuntu:**
```bash
sudo apt install librsvg2-bin
```

**Fedora:**
```bash
sudo dnf install librsvg2-tools
```

**RHEL/CentOS:**
```bash
sudo yum install librsvg2-tools
```

**Arch Linux:**
```bash
sudo pacman -S librsvg
```

**openSUSE:**
```bash
sudo zypper install librsvg
```

**Verification**:
```bash
rsvg-convert --version
```

#### Option 2: Inkscape

**Purpose**: Alternative SVG converter  
**Performance**: Slower but feature-rich

**Installation**:

**Debian/Ubuntu:**
```bash
sudo apt install inkscape
```

**Fedora:**
```bash
sudo dnf install inkscape
```

**Arch Linux:**
```bash
sudo pacman -S inkscape
```

**Verification**:
```bash
inkscape --version
```

#### Option 3: ImageMagick

**Purpose**: Image manipulation toolkit  
**Performance**: Moderate

**Installation**:

**Debian/Ubuntu:**
```bash
sudo apt install imagemagick
```

**Fedora:**
```bash
sudo dnf install ImageMagick
```

**Arch Linux:**
```bash
sudo pacman -S imagemagick
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

**Debian/Ubuntu:**
```bash
sudo apt install poppler-utils
```

**Fedora:**
```bash
sudo dnf install poppler-utils
```

**RHEL/CentOS:**
```bash
sudo yum install poppler-utils
```

**Arch Linux:**
```bash
sudo pacman -S poppler
```

**openSUSE:**
```bash
sudo zypper install poppler-tools
```

**Verification**:
```bash
pdfunite --version
```

#### Option 2: pdftk

**Purpose**: PDF toolkit for manipulation

**Installation**:

**Debian/Ubuntu:**
```bash
sudo apt install pdftk
# Or for newer versions
sudo apt install pdftk-java
```

**Fedora:**
```bash
sudo dnf install pdftk
```

**Arch Linux:**
```bash
# Available in AUR
yay -S pdftk
```

**Verification**:
```bash
pdftk --version
```

## Quick Install Commands

### Debian / Ubuntu
```bash
# Complete installation
sudo apt update
sudo apt install wireshark librsvg2-bin poppler-utils

# Add user to wireshark group
sudo usermod -aG wireshark $USER
```

### Fedora
```bash
# Complete installation
sudo dnf install wireshark librsvg2-tools poppler-utils

# Add user to wireshark group
sudo usermod -aG wireshark $USER
```

### RHEL / CentOS
```bash
# Complete installation
sudo yum install wireshark librsvg2-tools poppler-utils

# Add user to wireshark group
sudo usermod -aG wireshark $USER
```

### Arch Linux
```bash
# Complete installation
sudo pacman -S wireshark-qt librsvg poppler

# Add user to wireshark group
sudo usermod -aG wireshark $USER
```

### openSUSE
```bash
# Complete installation
sudo zypper install wireshark librsvg poppler-tools

# Add user to wireshark group
sudo usermod -aG wireshark $USER
```

## Plugin Directory

**Location**: `~/.local/lib/wireshark/plugin/`

**Note**: This matches your user rules. The installer will automatically create this directory.

**Alternative Locations** (not used by default):
- `~/.local/lib/wireshark/plugins/` (with 's')
- `~/.config/wireshark/plugins/`
- `/usr/lib/wireshark/plugins/` (system-wide, requires root)

## Permission Requirements

- **Read/Write**: `~/.local/lib/wireshark/plugin/` directory
- **Read**: Installation directory for the plugin file
- **Write**: `~/Documents/PacketReporter Reports/` for generated reports
- **Network Capture**: User must be in `wireshark` group (or run as root)

## Verification Checklist

Use this checklist to verify your installation:

```bash
#!/bin/bash

echo "=== PacketReporter Prerequisites Check ==="
echo ""

# 1. Check Wireshark
command -v wireshark &>/dev/null && echo "✓ Wireshark installed" || echo "✗ Wireshark missing"

# 2. Check Wireshark version
if command -v wireshark &>/dev/null; then
    VERSION=$(wireshark --version 2>/dev/null | head -n1 | awk '{print $2}')
    echo "  Version: $VERSION"
fi

# 3. Check user groups
echo ""
echo "User groups:"
groups | grep -q wireshark && echo "✓ User in wireshark group" || echo "⚠ User NOT in wireshark group (cannot capture packets)"

# 4. Check SVG converter (at least one needed)
echo ""
echo "SVG Converters:"
command -v rsvg-convert &>/dev/null && echo "✓ librsvg installed" || echo "✗ librsvg missing"
command -v inkscape &>/dev/null && echo "✓ Inkscape installed" || echo "✗ Inkscape missing"
command -v magick &>/dev/null && echo "✓ ImageMagick installed" || echo "✗ ImageMagick missing"

# 5. Check PDF combiner (at least one needed)
echo ""
echo "PDF Combiners:"
command -v pdfunite &>/dev/null && echo "✓ pdfunite installed" || echo "✗ pdfunite missing"
command -v pdftk &>/dev/null && echo "✓ pdftk installed" || echo "✗ pdftk missing"

# 6. Check plugin directory
echo ""
[ -d ~/.local/lib/wireshark/plugin ] && echo "✓ Plugin directory exists" || echo "⚠ Plugin directory not created yet"
```

Save this as `check-prereqs.sh` and run with `bash check-prereqs.sh`

## Troubleshooting

### Wireshark Not Found
```bash
# Check if package is installed
dpkg -l | grep wireshark    # Debian/Ubuntu
rpm -qa | grep wireshark    # Fedora/RHEL

# Reinstall if needed
sudo apt install --reinstall wireshark  # Debian/Ubuntu
sudo dnf reinstall wireshark            # Fedora
```

### Cannot Capture Packets
```bash
# Add user to wireshark group
sudo usermod -aG wireshark $USER

# Or configure dumpcap capabilities
sudo dpkg-reconfigure wireshark-common  # Debian/Ubuntu

# Verify group membership
groups

# Log out and log back in for changes to take effect
```

### PDF Export Not Working
```bash
# Install recommended dependencies
# Debian/Ubuntu
sudo apt install librsvg2-bin poppler-utils

# Fedora
sudo dnf install librsvg2-tools poppler-utils

# Verify installation
which rsvg-convert pdfunite
```

### Permission Denied
```bash
# Fix plugin directory permissions
mkdir -p ~/.local/lib/wireshark/plugin
chmod 755 ~/.local/lib/wireshark/plugin
chmod 644 ~/.local/lib/wireshark/plugin/packet_reporter.lua
```

### Library/Dependency Issues

#### Missing Shared Libraries
```bash
# Check library dependencies
ldd $(which wireshark)

# Install missing libraries
sudo apt install libglib2.0-0 libgtk-3-0  # Example for Debian/Ubuntu
```

#### GTK/Qt Issues
```bash
# Wireshark may use Qt or GTK
# For Qt version (recommended)
sudo apt install wireshark-qt

# For GTK version
sudo apt install wireshark-gtk
```

## Distribution-Specific Notes

### Ubuntu/Debian
- Default plugin directory: `~/.local/lib/wireshark/plugin/`
- User permissions handled via `wireshark` group
- May prompt during installation to allow non-root packet capture

### Fedora/RHEL
- SELinux may need configuration for packet capture
- Firewall may block capture on some interfaces

### Arch Linux
- Rolling release - always has latest Wireshark
- Plugin directory same as other distributions
- AUR packages available for additional tools

### openSUSE
- YaST can be used as GUI alternative for package management
- AppArmor may need configuration

## Wayland vs X11

Both display servers are supported, but some differences exist:

**X11**: Full support, no issues  
**Wayland**: Supported, but some GTK/Qt theming may differ

## Additional Resources

- [Wireshark Documentation](https://www.wireshark.org/docs/)
- [Wireshark Wiki - Linux](https://gitlab.com/wireshark/wireshark/-/wikis/CaptureSetup/CapturePrivileges)
- [Wireshark Lua API](https://www.wireshark.org/docs/wsdg_html_chunked/wsluarm.html)

## Minimum Installation

If you only want to run the plugin without PDF export:

```bash
# Debian/Ubuntu
sudo apt install wireshark

# Fedora
sudo dnf install wireshark
```

**Note**: Reports will still generate HTML output viewable in browser, but PDF export will be unavailable.

## Recommended Installation

For full functionality including PDF export:

```bash
# Debian/Ubuntu
sudo apt install wireshark librsvg2-bin poppler-utils
sudo usermod -aG wireshark $USER

# Fedora
sudo dnf install wireshark librsvg2-tools poppler-utils
sudo usermod -aG wireshark $USER
```

**Remember**: Log out and back in after adding user to wireshark group!
