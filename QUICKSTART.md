# PacketReporter - Quick Start Guide

Get started with PacketReporter in 5 minutes!

## Installation (One Command)

### macOS/Linux

```bash
cd /path/to/Communication-Matrix-Advanced
./install_packet_reporter.sh
```

Then restart Wireshark.

### Windows

```powershell
# Copy plugin to Wireshark plugins directory
copy packet_reporter.lua %APPDATA%\Wireshark\plugins\
```

Then restart Wireshark.

## First Report (3 Steps)

### Step 1: Load Traffic
- Open Wireshark
- Load a capture file: **File → Open** (or `Ctrl+O`)
- Or start a live capture

### Step 2: Generate Report
- Go to **Tools → PacketReporter**
- Choose **Summary Report** (fastest)
- Wait a few seconds for processing

### Step 3: View & Export
- Click **Open SVG** to view in browser
- Or click **Export PDF (A4)** to save PDF
- PDF saved to your home directory

## Menu Structure

```
Tools
└── PacketReporter
    ├── Summary Report        ← Quick overview with charts
    └── Detailed Report       ← Comprehensive analysis
    
└── Communication Matrix Report  ← Traffic visualization (separate)
```

## Report Types at a Glance

| Report | Processing Time | Best For | Output |
|--------|----------------|----------|--------|
| **Summary** | Fast (5-10s) | Quick assessment | 1-2 pages |
| **Detailed** | Moderate (10-30s) | Deep analysis | 3-6 pages |
| **Traffic Matrix** | Slower (30-60s) | Visual patterns | 1 page |

## Common Use Cases

### Use Case 1: Quick Traffic Overview
```
1. Load capture.pcap
2. Tools → PacketReporter → Summary Report
3. Review: Top IPs, protocols, ports
4. Export PDF for documentation
```

### Use Case 2: Investigate DNS Activity
```
1. Apply filter: dns
2. Tools → PacketReporter → Detailed Report
3. Look at Section 5: DNS Analysis
4. Identify suspicious queries
```

### Use Case 3: Web Traffic Analysis
```
1. Apply filter: http or tls
2. Tools → PacketReporter → Detailed Report
3. Review Section 6: HTTP Analysis
4. Check user-agents and hosts
```

### Use Case 4: Network Communication Map
```
1. Load capture with diverse traffic
2. Tools → Communication Matrix Report
3. Visual circular diagram generated
4. Identify communication patterns
```

## Display Filters (Copy & Paste)

**Common filters to use before generating reports:**

```bash
# Web traffic only
http or tls or dns

# Specific subnet
ip.addr == 192.168.1.0/24

# Exclude internal traffic
!(ip.addr == 10.0.0.0/8)

# HTTP errors
http.response.code >= 400

# DNS queries only
dns.flags.response == 0

# Suspicious ports
tcp.port in {1337 4444 5555 31337}
```

## PDF Export Requirements

**Required for PDF export (choose one):**

```bash
# macOS
brew install librsvg          # Recommended

# Ubuntu/Debian
sudo apt install librsvg2-bin  # Recommended

# Alternative: Inkscape
brew install inkscape          # macOS
sudo apt install inkscape      # Linux
```

Without a converter, you can still view reports in browser (SVG format).

## Troubleshooting (Quick Fixes)

### Plugin not showing in menu?
```bash
# Check plugin directory
ls ~/.local/lib/wireshark/plugins/packet_reporter.lua

# If not there, run installer again
./install_packet_reporter.sh
```

### PDF export not working?
```bash
# Install rsvg-convert
brew install librsvg           # macOS
sudo apt install librsvg2-bin  # Linux

# Then restart Wireshark
```

### Report generation slow?
```bash
# Apply a display filter first to reduce packets
# Example: Only last 1000 packets
frame.number >= 1000
```

### No data in report?
- Check if capture has the expected protocol
- Remove display filters temporarily
- Verify packets are loaded (check packet list)

## Tips & Tricks

### Tip 1: Speed Up Analysis
Apply filters before generating reports:
```
ip        # Only IP traffic (excludes ARP, etc.)
tcp       # Only TCP
```

### Tip 2: Compare Time Periods
```bash
# First 5 minutes
frame.time_relative <= 300

# Last 5 minutes
frame.time_relative >= (capture_duration - 300)
```

### Tip 3: Focus on External Traffic
```bash
# Exclude RFC1918 private IPs
!(ip.addr == 10.0.0.0/8 or ip.addr == 172.16.0.0/12 or ip.addr == 192.168.0.0/16)
```

### Tip 4: Find Specific Activity
```bash
# Large transfers
frame.len > 1400

# DNS to specific server
dns and ip.dst == 8.8.8.8
```

## Example Workflow

**Complete analysis workflow:**

```bash
# 1. Load capture
File → Open → capture.pcap

# 2. Quick overview
Tools → PacketReporter → Summary Report
# Review: General statistics, top talkers

# 3. Deep dive on suspicious IPs
# Note suspicious IP from summary (e.g., 203.0.113.50)
# Apply filter:
ip.addr == 203.0.113.50

# 4. Detailed analysis
Tools → PacketReporter → Detailed Report
# Review: All protocols from that IP

# 5. Check communication patterns
Tools → Communication Matrix Report
# Visual inspection of relationships

# 6. Export all reports
# Click Export PDF (A4) in each report window
# All saved to ~/PacketReport-*.pdf
```

## Keyboard Shortcuts (Wireshark)

Speed up your workflow:

```
Ctrl+O          Open capture file
Ctrl+R          Start capture
Ctrl+E          Stop capture
Ctrl+/          Apply display filter
Ctrl+Shift+F    Clear display filter
```

## File Locations

**Plugin:**
- macOS/Linux: `~/.local/lib/wireshark/plugins/packet_reporter.lua`
- Windows: `%APPDATA%\Wireshark\plugins\packet_reporter.lua`

**Generated PDFs:**
- All platforms: `~/PacketReport-YYYYMMDD-HHMMSS.pdf`
- Example: `~/PacketReport-20250125-143022.pdf`

## Next Steps

1. **Read full documentation:** `README_WIRESHARK_REPORTER.md`
2. **Try with sample captures:** Download from [Wireshark Wiki](https://wiki.wireshark.org/SampleCaptures)
3. **Experiment with filters:** Combine reports with different filters
4. **Share reports:** PDF exports are portable and professional

## Getting Help

**If something doesn't work:**

1. Check Wireshark console for errors:
   - Help → About Wireshark → Folders
   - Look for "Personal Lua Plugins" folder
   
2. Verify Wireshark version:
   - Help → About Wireshark
   - Should be 4.0 or later

3. Check README_WIRESHARK_REPORTER.md for detailed troubleshooting

4. Test with a small capture first (< 10,000 packets)

## Sample Commands

**Generate test traffic for demo:**

```bash
# Generate HTTP traffic
curl http://example.com

# Generate DNS traffic  
nslookup google.com

# Generate HTTPS traffic
curl https://www.wireshark.org
```

Capture this traffic in Wireshark, then generate reports!

---

**That's it! You're ready to generate professional network analysis reports.**

For advanced features and detailed explanations, see `README_WIRESHARK_REPORTER.md`.
