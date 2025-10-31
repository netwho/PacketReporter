# PacketReporter - Platform Installers

This directory contains platform-specific installers for the PacketReporter plugin. Each installer includes prerequisite checking, automatic installation, and detailed requirements documentation.

## Quick Start

Choose your operating system and run the appropriate installer:

### macOS
```bash
cd installers/macos
./install.sh
```

### Linux
```bash
cd installers/linux
./install.sh
```

### Windows
```powershell
cd installers\windows
powershell -ExecutionPolicy Bypass -File install.ps1
```

## Directory Structure

```
installers/
├── README.md              # This file
├── macos/                 # macOS installer
│   ├── install.sh        # Installation script (Bash)
│   ├── requirements.md   # Detailed prerequisites
│   └── packet_reporter.lua
├── linux/                 # Linux installer
│   ├── install.sh        # Installation script (Bash)
│   ├── requirements.md   # Detailed prerequisites
│   └── packet_reporter.lua
└── windows/               # Windows installer
    ├── install.ps1       # Installation script (PowerShell)
    ├── requirements.md   # Detailed prerequisites
    └── packet_reporter.lua
```

## What the Installers Do

All installers perform the following tasks:

1. ✅ **Check Prerequisites**
   - Verify Wireshark 4.0+ is installed
   - Check for PDF export dependencies
   - Report version information

2. 📦 **Install Plugin**
   - Create plugin directory if needed
   - Copy `packet_reporter.lua` to correct location
   - Set appropriate file permissions

3. 🔍 **Dependency Check**
   - Detect SVG converters (rsvg-convert, Inkscape, ImageMagick)
   - Detect PDF combiners (pdfunite, pdftk)
   - Provide installation commands for missing tools

4. 📝 **Post-Installation**
   - Display next steps
   - Show plugin location
   - Link to documentation

## Platform-Specific Details

### macOS

**Installer**: `macos/install.sh`  
**Requirements**: See `macos/requirements.md`

**Key Features**:
- Detects Intel vs Apple Silicon
- Checks for Homebrew
- Verifies Wireshark in `/Applications/`
- Uses plugin directory: `~/.local/lib/wireshark/plugin/`

**Prerequisites**:
- Wireshark 4.0+
- Optional: Homebrew, librsvg, poppler

**Installation**:
```bash
cd installers/macos
chmod +x install.sh  # Make executable (if needed)
./install.sh
```

**After Installation**:
```bash
# Install optional dependencies
brew install librsvg poppler
```

---

### Linux

**Installer**: `linux/install.sh`  
**Requirements**: See `linux/requirements.md`

**Key Features**:
- Detects package manager (apt, dnf, yum, pacman, zypper)
- Supports Debian, Ubuntu, Fedora, RHEL, Arch, openSUSE
- Provides distro-specific commands
- Uses plugin directory: `~/.local/lib/wireshark/plugin/`

**Prerequisites**:
- Wireshark 4.0+
- User in `wireshark` group (for packet capture)
- Optional: librsvg2-bin, poppler-utils

**Installation**:
```bash
cd installers/linux
chmod +x install.sh  # Make executable (if needed)
./install.sh
```

**After Installation**:
```bash
# Debian/Ubuntu
sudo apt install librsvg2-bin poppler-utils
sudo usermod -aG wireshark $USER
# Log out and back in

# Fedora
sudo dnf install librsvg2-tools poppler-utils
sudo usermod -aG wireshark $USER
# Log out and back in
```

---

### Windows

**Installer**: `windows/install.ps1`  
**Requirements**: See `windows/requirements.md`

**Key Features**:
- Checks both Program Files locations (x64/x86)
- Detects Chocolatey package manager
- Provides manual installation links
- Uses plugin directory: `%APPDATA%\Wireshark\plugins\`

**Prerequisites**:
- Wireshark 4.0+ with Npcap
- Optional: Chocolatey, rsvg-convert, poppler

**Installation**:
```powershell
cd installers\windows
powershell -ExecutionPolicy Bypass -File install.ps1
```

**After Installation** (with Chocolatey):
```powershell
choco install rsvg-convert poppler
```

**After Installation** (manual):
- Download [rsvg-convert](https://github.com/miyako/console-rsvg-convert/releases)
- Download [Poppler](https://github.com/oschwartz10612/poppler-windows/releases)
- Add to PATH

---

## Plugin Installation Locations

The installer places the Lua plugin in the following locations:

| Platform | Directory |
|----------|-----------|
| macOS    | `~/.local/lib/wireshark/plugin/` |
| Linux    | `~/.local/lib/wireshark/plugin/` |
| Windows  | `%APPDATA%\Wireshark\plugins\` |

**Note**: The macOS/Linux location matches your Warp rules configuration.

## Requirements Summary

### Required (All Platforms)
- **Wireshark 4.0+** - Network protocol analyzer

### Optional (For PDF Export)
- **SVG Converter** (choose one):
  - `rsvg-convert` (recommended - fastest)
  - Inkscape
  - ImageMagick

- **PDF Combiner** (choose one):
  - `pdfunite` (recommended - part of Poppler)
  - `pdftk`

## Installation Verification

After running the installer, verify the installation:

### All Platforms
1. Restart Wireshark
2. Go to **Help → About Wireshark → Plugins**
3. Look for `packet_reporter.lua` in the list
4. Go to **Tools** menu
5. You should see **PacketReporter** submenu

### Check Plugin File

**macOS/Linux**:
```bash
ls -l ~/.local/lib/wireshark/plugin/packet_reporter.lua
```

**Windows**:
```powershell
Test-Path "$env:APPDATA\Wireshark\plugins\packet_reporter.lua"
```

## Troubleshooting

### Plugin Not Appearing in Wireshark

1. **Check plugin location**:
   - Verify file is in correct directory
   - Check file has `.lua` extension

2. **Check permissions**:
   ```bash
   # macOS/Linux
   chmod 644 ~/.local/lib/wireshark/plugin/packet_reporter.lua
   ```

3. **Check Wireshark Lua support**:
   - Go to Help → About Wireshark
   - Look for "with Lua" in version info

4. **Check for errors**:
   - Open Wireshark console (View → Internals → Lua)
   - Look for error messages

### PDF Export Not Working

**Install dependencies**:

**macOS**:
```bash
brew install librsvg poppler
```

**Linux (Debian/Ubuntu)**:
```bash
sudo apt install librsvg2-bin poppler-utils
```

**Linux (Fedora)**:
```bash
sudo dnf install librsvg2-tools poppler-utils
```

**Windows**:
```powershell
choco install rsvg-convert poppler
```

### Permission Errors

**macOS/Linux**:
```bash
# Fix directory permissions
mkdir -p ~/.local/lib/wireshark/plugin
chmod 755 ~/.local/lib/wireshark/plugin
chmod 644 ~/.local/lib/wireshark/plugin/packet_reporter.lua
```

**Windows**:
```powershell
# Run as Administrator if needed, or fix permissions
$pluginDir = "$env:APPDATA\Wireshark\plugins"
New-Item -ItemType Directory -Force -Path $pluginDir
```

## Uninstallation

### macOS/Linux
```bash
rm ~/.local/lib/wireshark/plugin/packet_reporter.lua
```

### Windows
```powershell
Remove-Item "$env:APPDATA\Wireshark\plugins\packet_reporter.lua"
```

## Support & Documentation

Each platform directory contains detailed documentation:

- **requirements.md** - Complete prerequisites and installation instructions
- **install script** - Automated installation with checks

Additional documentation in project root:
- `README.md` - Full user guide
- `QUICKSTART.md` - Quick start guide
- `PROJECT_OVERVIEW.md` - Architecture details
- `CONTRIBUTING.md` - Contribution guidelines

## Advanced Usage

### Custom Plugin Directory

If you need to use a different plugin directory:

**macOS/Linux**:
```bash
# Edit install.sh before running
PLUGIN_DIR="/your/custom/path"
```

**Windows**:
```powershell
# Edit install.ps1 before running
$pluginDir = "C:\Your\Custom\Path"
```

### System-Wide Installation

For system-wide installation (requires admin/root):

**macOS/Linux**:
```bash
sudo mkdir -p /usr/local/lib/wireshark/plugins
sudo cp packet_reporter.lua /usr/local/lib/wireshark/plugins/
sudo chmod 644 /usr/local/lib/wireshark/plugins/packet_reporter.lua
```

**Windows** (as Administrator):
```powershell
Copy-Item packet_reporter.lua "$env:ProgramFiles\Wireshark\plugins\"
```

### Automated/Silent Installation

All installers support non-interactive use:

**macOS/Linux**:
```bash
./install.sh 2>&1 | tee install.log
```

**Windows**:
```powershell
.\install.ps1 2>&1 | Tee-Object install.log
```

## Version Information

- **Plugin Version**: See `packet_reporter.lua` header
- **Wireshark Compatibility**: 4.0+
- **Lua Version**: 5.2+

## License

MIT License - See main project LICENSE file

## Contributing

See `CONTRIBUTING.md` in project root for development guidelines.

## Issues

Report issues on the project's GitHub Issues page.

---

**Quick Links**:
- [Main Documentation](../README.md)
- [Quick Start Guide](../QUICKSTART.md)
- [Project Overview](../PROJECT_OVERVIEW.md)
