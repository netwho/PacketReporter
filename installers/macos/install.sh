#!/usr/bin/env bash
#
# PacketReporter Installation Script
# Installs the PacketReporter plugin to the appropriate plugins directory
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}PacketReporter Installation${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
else
    echo -e "${RED}Error: Unsupported OS: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Detected OS: $OS"

# Determine plugin directory
PLUGIN_DIR="$HOME/.local/lib/wireshark/plugins"

echo -e "${GREEN}✓${NC} Plugin directory: $PLUGIN_DIR"

# Create plugin directory if it doesn't exist
if [ ! -d "$PLUGIN_DIR" ]; then
    echo -e "${YELLOW}→${NC} Creating plugin directory..."
    mkdir -p "$PLUGIN_DIR"
    echo -e "${GREEN}✓${NC} Directory created"
else
    echo -e "${GREEN}✓${NC} Directory exists"
fi

# Copy the plugin file
echo -e "${YELLOW}→${NC} Installing packet_reporter.lua..."
cp "$SCRIPT_DIR/packet_reporter.lua" "$PLUGIN_DIR/"
chmod 644 "$PLUGIN_DIR/packet_reporter.lua"
echo -e "${GREEN}✓${NC} Plugin installed"

# Create config directory for cover page customization
CONFIG_DIR="$HOME/.packet_reporter"
echo -e "${YELLOW}→${NC} Setting up configuration directory..."

if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
    echo -e "${GREEN}✓${NC} Created config directory: $CONFIG_DIR"
else
    echo -e "${GREEN}✓${NC} Config directory exists"
fi

# Copy default logo and description if they don't exist
if [ ! -f "$CONFIG_DIR/Logo.png" ] && [ -f "$SCRIPT_DIR/Logo.png" ]; then
    cp "$SCRIPT_DIR/Logo.png" "$CONFIG_DIR/"
    echo -e "${GREEN}✓${NC} Copied default logo"
fi

if [ ! -f "$CONFIG_DIR/packet_reporter.txt" ] && [ -f "$SCRIPT_DIR/packet_reporter.txt" ]; then
    cp "$SCRIPT_DIR/packet_reporter.txt" "$CONFIG_DIR/"
    echo -e "${GREEN}✓${NC} Copied default description"
fi

# Check for PDF converters
echo ""
echo -e "${BLUE}Checking for PDF converters...${NC}"

HAS_CONVERTER=false

# Check for rsvg-convert
if command -v rsvg-convert &> /dev/null; then
    echo -e "${GREEN}✓${NC} rsvg-convert found"
    HAS_CONVERTER=true
else
    echo -e "${YELLOW}✗${NC} rsvg-convert not found"
fi

# Check for inkscape
if command -v inkscape &> /dev/null; then
    echo -e "${GREEN}✓${NC} inkscape found"
    HAS_CONVERTER=true
else
    echo -e "${YELLOW}✗${NC} inkscape not found"
fi

# Check for imagemagick
if command -v magick &> /dev/null || command -v convert &> /dev/null; then
    echo -e "${GREEN}✓${NC} imagemagick found"
    HAS_CONVERTER=true
else
    echo -e "${YELLOW}✗${NC} imagemagick not found"
fi

# Check for PDF combiners
echo ""
echo -e "${BLUE}Checking for PDF combiners...${NC}"

HAS_COMBINER=false

# Check for pdfunite
if command -v pdfunite &> /dev/null; then
    echo -e "${GREEN}✓${NC} pdfunite found"
    HAS_COMBINER=true
else
    echo -e "${YELLOW}✗${NC} pdfunite not found"
fi

# Check for pdftk
if command -v pdftk &> /dev/null; then
    echo -e "${GREEN}✓${NC} pdftk found"
    HAS_COMBINER=true
else
    echo -e "${YELLOW}✗${NC} pdftk not found"
fi

# Installation recommendations
echo ""
if [ "$HAS_CONVERTER" = false ] || [ "$HAS_COMBINER" = false ]; then
    echo -e "${YELLOW}⚠${NC}  ${YELLOW}Recommended dependencies missing${NC}"
    echo ""
    echo "For full PDF export functionality, install:"
    echo ""
    if [ "$OS" == "macOS" ]; then
        [ "$HAS_CONVERTER" = false ] && echo "  brew install librsvg"
        [ "$HAS_COMBINER" = false ] && echo "  brew install poppler"
    elif [ "$OS" == "Linux" ]; then
        [ "$HAS_CONVERTER" = false ] && echo "  sudo apt install librsvg2-bin   # Debian/Ubuntu"
        [ "$HAS_COMBINER" = false ] && echo "  sudo apt install poppler-utils  # Debian/Ubuntu"
    fi
    echo ""
    echo "The plugin will still work, but PDF export will be limited."
else
    echo -e "${GREEN}✓${NC} All dependencies installed"
fi

# Final instructions
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart Wireshark"
echo "  2. Go to Tools → PacketReporter"
echo "  3. Choose a report type:"
echo "     • Summary Report - Quick overview"
echo "     • Detailed Report (A4) - Comprehensive analysis"
echo "     • Detailed Report (Legal) - US Legal paper size"
echo ""
echo "Customization:"
echo "  Detailed reports include a professional cover page."
echo "  Customize by editing files in: $CONFIG_DIR"
echo "     • Logo.png - Your company/organization logo"
echo "     • packet_reporter.txt - Report description (3 lines max)"
echo ""
echo "Documentation:"
echo "  • README.md - Full user guide"
echo "  • QUICKSTART.md - Quick start guide"
echo "  • PROJECT_OVERVIEW.md - Architecture details"
echo ""
echo -e "${GREEN}Generated reports will be saved to:${NC}"
echo "  ~/Documents/PacketReporter Reports/"
echo ""
