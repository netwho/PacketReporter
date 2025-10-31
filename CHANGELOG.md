# Changelog

All notable changes to the PacketReporter project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2025-01-27

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

[1.0.0]: https://github.com/netwho/PacketReporter/releases/tag/v1.0.0
