# Changelog

All notable changes to the PacketReporter project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.2.4] - 2025-01-01

### Changed
- **TLS/SSL Version Detection**: Completely rewritten detection logic for improved accuracy
  - Now prioritizes `supported_versions` extension (RFC 8446) for TLS 1.3 detection
  - Uses TLS 1.3 cipher suites (0x1301-0x1305) as secondary detection method
  - Enhanced protocol string pattern matching for various TLS version formats
  - **Important**: Only counts TLS versions from handshake packets to avoid false positives
  - Removed misleading `record.version` fallback (TLS 1.3 uses 0x0303 for compatibility, causing false TLS 1.2 detections)
  - TLS/SSL/QUIC Version Distribution chart now shows "Values represent the number of observed handshakes" instead of packet counts
- **Dependency Reporting**: Streamlined dependency checking output
  - Only reports "All dependencies met" when everything is available
  - Shows detailed missing dependency information only when something is missing
  - Prevents PDF export if required dependencies are not available
- **Chart Display**: Improved TLS version distribution bar chart
  - Value labels positioned at end of bars with white (inverted) text for better visibility
  - Labels no longer extend beyond bar boundaries

### Fixed
- **Windows**: Significantly reduced visible CMD console windows during operation
  - Minimized console flashing during PDF generation (from 10-20+ to near-zero visible windows)
  - Wrapped all commands with `cmd /c` and output redirection to NUL
  - Startup dependency checks still show 3-5 brief flashes (Lua limitation on Windows)
  - See WINDOWS_CONSOLE_FIX.md for technical details
- **TLS 1.3 Detection**: Fixed incorrect TLS 1.2 reporting for TLS 1.3 connections
  - Previously, TLS 1.3 application data packets were incorrectly counted as TLS 1.2 due to `record.version` compatibility value
  - Now correctly identifies TLS 1.3 using handshake-specific fields
- **QUIC Detection**: Improved QUIC protocol detection via UDP port 443 and protocol string matching

### Removed
- Debug code and verbose output removed for cleaner operation
  - Removed protocol string sampling debug output
  - Removed detection method statistics tracking
  - Removed field loading debug messages

---

## [0.2.0] - 2025-01-31 (Public Beta)

> **Note**: This is a public beta release. While functional, the software is not yet production-ready. Please report any issues you encounter.

### Added
- **Summary Report** with quick traffic overview
  - Overview statistics panel
  - Top 10 IP addresses bar chart
  - Protocol distribution pie chart
  - Top 5 TCP ports bar chart
  
- **Detailed Report** with comprehensive analysis
  - Section 1: PCAP file information and summary
  - Section 2: Top 10 IP addresses visualization
  - Section 3: Protocol distribution analysis
  - Section 4: IP Communication Matrix with circular visualization
  - Section 5: Port analysis (TCP and UDP)
  - Section 6: DNS analysis with resource record types and authoritative responses
  - Section 7: TLS/SSL analysis (versions, SNI, certificates)
  - Section 8: HTTP analysis (user agents, hosts, status codes)
  - Section 9: MAC layer analysis
  - Section 10: IP layer analysis
  - Section 11: TCP analysis
  
- **Multi-page PDF export**
  - A4 paper size support (794×1123px)
  - Legal paper size support (816×1344px)
  - Intelligent page breaks
  - 60px bottom margin enforcement
  - Auto-open PDFs after creation
  
- **Automatic report saving**
  - Reports saved to ~/Documents/PacketReporter Reports/
  - Timestamped filenames (PacketReport-YYYYMMDD-HHMMSS.pdf)
  - Directory auto-creation
  
- **Dependency checking**
  - Startup check for required tools
  - Warning window with installation instructions
  - Support for rsvg-convert, inkscape, imagemagick
  - PDF combiner support (pdfunite, pdftk)
  
- **Rich visualizations**
  - Bar charts with value labels
  - Pie charts with percentages and legends
  - Circular communication matrix
  - Color-coded traffic intensity
  - Professional SVG generation
  
- **Installation tools**
  - Cross-platform install.sh script
  - Automatic dependency detection
  - Plugin directory setup
  
- **Comprehensive documentation**
  - README.md (full user guide)
  - QUICKSTART.md (5-minute guide)
  - PROJECT_OVERVIEW.md (architecture)
  
### Features
- Works with Wireshark display filters
- Processes currently loaded packets
- No external Lua dependencies
- Pure Wireshark Lua API implementation
- Cross-platform (macOS, Linux, Windows)

### Technical Details
- 1936 lines of Lua code
- 10+ data collection functions
- Chart generation system
- Multi-converter PDF export system
- Intelligent page layout engine

---

## Future Releases

### Planned Features
- SMTP/email traffic analysis
- FTP command analysis
- SIP/RTP VoIP analysis
- ICMP analysis (ping, traceroute)
- Configurable top-N limits
- Report templates
- Custom color schemes

---

[0.2.0]: https://github.com/netwho/PacketReporter/releases/tag/v0.2.0
