--[[
PacketReporter - Comprehensive Network Analysis Plugin
Menu: Tools -> PacketReporter

Features:
- Summary Report: Overview with statistics and charts
- Traffic Matrix: Circular visualization of communications (from Circle View)
- Detailed Report: In-depth analysis based on Tranalyzer capabilities

All reports work with currently loaded/captured packets and applied filters.
Exports to PDF with paper size options (A4 / Legal).

Tested with Wireshark 4.x
--]]

if not gui_enabled() then return end

-- Register plugin info with Wireshark
set_plugin_info({
    version = "0.2.4",
    author = "Walter Hofstetter",
    description = "Generate comprehensive network analysis reports with charts and PDF export",
    repository = "https://github.com/netwho/PacketReporter"
})

------------------------------------------------------------
-- Paper Size Configurations
------------------------------------------------------------
local PAPER_SIZES = {
  A4 = { width = 794, height = 1123, name = "A4" },      -- 210mm x 297mm at 96 DPI
  LEGAL = { width = 816, height = 1344, name = "Legal" }  -- 8.5" x 14" at 96 DPI
}

-- Global setting for paper size (can be changed by user)
local current_paper_size = PAPER_SIZES.A4

------------------------------------------------------------
-- Fields Extraction
------------------------------------------------------------
local F = Field.new

-- L2 (Ethernet)
local f_eth_src = F("eth.src")
local f_eth_dst = F("eth.dst")

-- L2 (Wi-Fi / 802.11)
local f_wlan_sa  = F("wlan.sa")
local f_wlan_da  = F("wlan.da")

-- L3 IPv4/IPv6
local f_ip_src  = F("ip.src")
local f_ip_dst  = F("ip.dst")
local f_ip6_src = F("ipv6.src")
local f_ip6_dst = F("ipv6.dst")

-- L4 Ports
local f_tcp_srcport = F("tcp.srcport")
local f_tcp_dstport = F("tcp.dstport")
local f_udp_srcport = F("udp.srcport")
local f_udp_dstport = F("udp.dstport")

-- Protocols
local f_frame_len = F("frame.len")
local f_frame_protocols = F("frame.protocols")
local f_frame_time = F("frame.time_epoch")

-- DNS
local f_dns_qry_name = F("dns.qry.name")
local f_dns_a = F("dns.a")
local f_dns_aaaa = F("dns.aaaa")
local f_dns_resp_name = F("dns.resp.name")

-- Additional DNS fields (safe loading)
local f_dns_qry_type, f_dns_flags_response, f_dns_flags_authoritative
pcall(function() f_dns_qry_type = F("dns.qry.type") end)
pcall(function() f_dns_flags_response = F("dns.flags.response") end)
pcall(function() f_dns_flags_authoritative = F("dns.flags.authoritative") end)

-- HTTP
local f_http_user_agent = F("http.user_agent")
local f_http_host = F("http.host")
local f_http_server = F("http.server")
local f_http_content_type = F("http.content_type")
local f_http_response_code = F("http.response.code")

-- TLS/HTTPS (try both ssl and tls prefixes)
local f_tls_handshake_sni, f_tls_cert_common_name
pcall(function() f_tls_handshake_sni = F("ssl.handshake.extensions_server_name") end)
if not f_tls_handshake_sni then pcall(function() f_tls_handshake_sni = F("tls.handshake.extensions_server_name") end) end
pcall(function() f_tls_cert_common_name = F("x509sat.printableString") end)

-- Additional TLS fields (safe loading) - try both ssl and tls prefixes
local f_tls_version, f_tls_handshake_version, f_tls_record_version
local f_tls_handshake_ciphersuite, f_tls_cert_subject_cn
pcall(function() f_tls_record_version = F("ssl.record.version") end)
if not f_tls_record_version then pcall(function() f_tls_record_version = F("tls.record.version") end) end
pcall(function() f_tls_handshake_version = F("ssl.handshake.version") end)
if not f_tls_handshake_version then pcall(function() f_tls_handshake_version = F("tls.handshake.version") end) end
pcall(function() f_tls_handshake_ciphersuite = F("ssl.handshake.ciphersuite") end)
if not f_tls_handshake_ciphersuite then pcall(function() f_tls_handshake_ciphersuite = F("tls.handshake.ciphersuite") end) end
pcall(function() f_tls_cert_subject_cn = F("x509sat.uTF8String") end)

-- Phase 2: MAC Layer (with safe field loading)
local f_eth_dst_type, f_eth_src_oui
pcall(function() f_eth_dst_type = F("eth.dst.type") end)
pcall(function() f_eth_src_oui = F("eth.src_resolved") end)

-- Phase 2: IP Layer
local f_ip_ttl, f_ip_flags_mf, f_ip_frag_offset, f_ip_dsfield, f_ip_proto
pcall(function() f_ip_ttl = F("ip.ttl") end)
pcall(function() f_ip_flags_mf = F("ip.flags.mf") end)
pcall(function() f_ip_frag_offset = F("ip.frag_offset") end)
pcall(function() f_ip_dsfield = F("ip.dsfield") end)
pcall(function() f_ip_proto = F("ip.proto") end)

-- Phase 2: TCP Layer
local f_tcp_window_size, f_tcp_len, f_tcp_analysis_ack_rtt
pcall(function() f_tcp_window_size = F("tcp.window_size") end)
pcall(function() f_tcp_len = F("tcp.len") end)
pcall(function() f_tcp_analysis_ack_rtt = F("tcp.analysis.ack_rtt") end)

-- Phase 2: UDP Layer (for QUIC detection)
local f_udp_port, f_udp_dstport, f_udp_srcport
pcall(function() f_udp_port = F("udp.port") end)
pcall(function() f_udp_dstport = F("udp.dstport") end)
pcall(function() f_udp_srcport = F("udp.srcport") end)

-- TLS supported_versions extension (for accurate TLS 1.3 detection)
-- The field can appear multiple times (one per supported version), so we need to check all values
-- Try multiple possible field names
local f_tls_supported_version
pcall(function() f_tls_supported_version = F("tls.handshake.extensions.supported_version") end)
if not f_tls_supported_version then
  pcall(function() f_tls_supported_version = F("tls.handshake.extensions_supported_version") end)
end
if not f_tls_supported_version then
  pcall(function() f_tls_supported_version = F("tls.handshake.extensions_supported_versions") end)
end
if not f_tls_supported_version then
  pcall(function() f_tls_supported_version = F("ssl.handshake.extensions.supported_version") end)
end
if not f_tls_supported_version then
  pcall(function() f_tls_supported_version = F("ssl.handshake.extensions_supported_version") end)
end
if not f_tls_supported_version then
  pcall(function() f_tls_supported_version = F("ssl.handshake.extensions_supported_versions") end)
end

------------------------------------------------------------
-- Utility Functions
------------------------------------------------------------
local function f2s(field)
  if not field then return nil end
  local ok, v = pcall(function() return tostring(field()) end)
  if ok and v and v ~= "" then return v end
  return nil
end

local function f2n(field)
  if not field then return nil end
  local ok, v = pcall(function() return tonumber(tostring(field())) end)
  if ok and v then return v end
  return nil
end

local function xml_escape(s)
  if not s then return "" end
  s = tostring(s)
  s = s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
       :gsub("\"","&quot;"):gsub("'","&apos;")
  return s
end

local function ascii_only(s)
  return (s:gsub("[^\x20-\x7E]", "?"))
end

local function format_bytes(bytes)
  if bytes < 1024 then return string.format("%d B", bytes)
  elseif bytes < 1024*1024 then return string.format("%.1f KB", bytes/1024)
  elseif bytes < 1024*1024*1024 then return string.format("%.1f MB", bytes/(1024*1024))
  else return string.format("%.1f GB", bytes/(1024*1024*1024)) end
end

local function try_open_in_browser(path)
  if type(browser_open_url) == "function" then
    local ok = pcall(function() browser_open_url("file://"..path) end)
    if ok then return true end
  end
  return false
end

local function tmp_svg()
  return os.tmpname() .. ".svg"
end

local function tmp_png()
  return os.tmpname() .. ".png"
end

local function get_home_dir()
  local home = os.getenv("HOME") or os.getenv("USERPROFILE")
  if home and home ~= "" then return home end
  local tmp = os.tmpname()
  return tmp:match("^(.*)[/\\]") or "."
end

-- Detect OS
local function is_windows()
  return package.config:sub(1,1) == '\\'
end

local IS_WINDOWS = is_windows()

-- Cache for detected converters (avoid re-detection)
local CACHED_CONVERTERS = nil

-- VBScript wrapper for completely silent Windows execution (no window flashes)
local function run_vbs_silent(cmd)
  -- Create temporary batch file with the command
  local bat_path = os.tmpname() .. ".bat"
  local f = io.open(bat_path, "w")
  if not f then return false end
  f:write("@echo off\n")
  f:write(cmd .. "\n")
  f:close()
  
  -- Create VBScript to run batch file silently
  local vbs_path = os.tmpname() .. ".vbs"
  local vbs_content = string.format([[
Set objShell = CreateObject("WScript.Shell")
returnCode = objShell.Run("%s", 0, True)
WScript.Quit returnCode
]], bat_path:gsub("\\", "\\\\"))  -- Escape backslashes for VBScript
  
  f = io.open(vbs_path, "w")
  if f then
    f:write(vbs_content)
    f:close()
    
    -- Execute VBScript (completely silent, no window, waits for completion)
    -- Redirect output to suppress console
    local rc = os.execute('cscript.exe //Nologo "' .. vbs_path .. '" >NUL 2>&1')
    
    -- Clean up both temp files
    os.remove(vbs_path)
    os.remove(bat_path)
    
    return rc == true or rc == 0
  end
  
  os.remove(bat_path)  -- Clean up batch file if VBScript creation failed
  return false
end

-- Silent command execution for Windows
local function run_silent(cmd)
  if IS_WINDOWS then
    -- Use VBScript wrapper for completely silent execution (no flashes)
    return run_vbs_silent(cmd)
  else
    local rc = os.execute(cmd)
    return rc == true or rc == 0
  end
end

-- Original run_sh for compatibility
local function run_sh(cmd)
  if IS_WINDOWS then
    -- Redirect output to suppress window
    local rc = os.execute(cmd .. " >NUL 2>NUL")
    return rc == true or rc == 0
  else
    local rc = os.execute(cmd)
    return rc == true or rc == 0
  end
end

-- Silent popen for Windows (returns handle or nil)
local function popen_silent(cmd, mode)
  if IS_WINDOWS then
    -- Redirect stderr to suppress errors, but don't use PowerShell wrapper
    -- as it interferes with command detection
    return io.popen(cmd .. " 2>NUL", mode)
  else
    return io.popen(cmd, mode)
  end
end

local function find_cmd(candidates)
  for _,c in ipairs(candidates) do
    if c:find("/") or c:find("\\") then
      -- Full path candidate - check for .exe extension on Windows
      local paths_to_check = {c}
      if IS_WINDOWS and not c:match("%.exe$") then
        table.insert(paths_to_check, c .. ".exe")
      end
      
      for _, path in ipairs(paths_to_check) do
        local f = io.open(path, "r")
        if f then
          f:close()
          return path
        end
      end
    else
      -- Command name in PATH
      if IS_WINDOWS then
        -- On Windows, use where.exe to find command
        local handle = popen_silent("where " .. c, "r")
        if handle then
          local result = handle:read("*l")  -- Read first line only
          handle:close()
          if result and result ~= "" and not result:match("Could not find") and not result:match("INFO:") then
            -- Command exists in PATH, return the command name (not full path)
            return c
          end
        end
      else
        if run_sh("sh -c 'command -v "..c.." >/dev/null 2>&1'") then
          return c
        end
      end
    end
  end
  return nil
end

-- Read logo and description from user config
-- Base64 encoding function
local function encode_base64(data)
  local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  return ((data:gsub('.', function(x) 
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

local function read_config_files()
  local home = get_home_dir()
  local config_dir = home .. "/.packet_reporter"
  local logo_path = config_dir .. "/Logo.png"
  local desc_path = config_dir .. "/packet_reporter.txt"
  
  local config = {
    logo_exists = false,
    logo_base64 = nil,
    description = {}
  }
  
  -- Read and encode logo as base64
  local logo_file = io.open(logo_path, "rb")
  if logo_file then
    local logo_data = logo_file:read("*all")
    logo_file:close()
    if logo_data and #logo_data > 0 then
      config.logo_exists = true
      config.logo_base64 = encode_base64(logo_data)
    end
  end
  
  -- Read description file (max 3 lines)
  local desc_file = io.open(desc_path, "r")
  if desc_file then
    local line_count = 0
    for line in desc_file:lines() do
      if line_count < 3 then
        table.insert(config.description, line)
        line_count = line_count + 1
      end
    end
    desc_file:close()
  end
  
  -- Use defaults if no description
  if #config.description == 0 then
    config.description = {
      "PacketReporter - Network Traffic Analysis Report",
      "Comprehensive analysis of captured network packets",
      "Generated: " .. os.date("%Y-%m-%d %H:%M:%S")
    }
  end
  
  return config
end

-- Generate cover page with logo, description, and TOC
local function generate_cover_page(paper, config, toc_items)
  local out = {}
  local function add(s) table.insert(out, s) end
  
  add('<?xml version="1.0" encoding="UTF-8"?>\n')
  add('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n')
  add(string.format('<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="%d" height="%d">\n', paper.width, paper.height))
  add('<rect x="0" y="0" width="100%" height="100%" fill="white"/>\n')
  
  -- Logo (if exists) - centered at top
  local y_pos = 100
  if config.logo_exists and config.logo_base64 then
    -- Embed logo as base64 data URI
    add(string.format('<image x="%d" y="%d" width="400" height="200" xlink:href="data:image/png;base64,%s" preserveAspectRatio="xMidYMid meet"/>\n',
      (paper.width - 400) / 2, y_pos, config.logo_base64))
    y_pos = y_pos + 250
  else
    -- Text logo as fallback
    add(string.format('<text x="%d" y="%d" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="48" font-weight="700" fill="#2C7BB6">PacketReporter</text>\n',
      paper.width / 2, y_pos))
    y_pos = y_pos + 100
  end
  
  -- Description (3 lines, left-aligned)
  for i, line in ipairs(config.description) do
    add(string.format('<text x="100" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#333">%s</text>\n',
      y_pos + (i-1) * 25, xml_escape(line)))
  end
  y_pos = y_pos + 120
  
  -- Horizontal line separator
  add(string.format('<line x1="80" y1="%d" x2="%d" y2="%d" stroke="#2C7BB6" stroke-width="2"/>\n',
    y_pos, paper.width - 80, y_pos))
  y_pos = y_pos + 40
  
  -- Table of Contents title
  add(string.format('<text x="100" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="20" font-weight="700" fill="#2C7BB6">Table of Contents</text>\n',
    y_pos))
  y_pos = y_pos + 80  -- Add extra space (2 section title heights)
  
  -- TOC items
  for _, item in ipairs(toc_items) do
    -- Section title (left)
    add(string.format('<text x="120" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#333">%s</text>\n',
      y_pos, xml_escape(item.title)))
    
    -- Page number (right)
    add(string.format('<text x="%d" y="%d" text-anchor="end" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">%d</text>\n',
      paper.width - 120, y_pos, item.page))
    
    y_pos = y_pos + 25
  end
  
  -- Footer
  add(string.format('<text x="%d" y="%d" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="#999">Generated by PacketReporter on %s</text>\n',
    paper.width / 2, paper.height - 50, os.date("%Y-%m-%d %H:%M:%S")))
  
  add('</svg>\n')
  return table.concat(out)
end

local function detect_converters()
  -- Return cached results if available (avoid repeated detection)
  if CACHED_CONVERTERS then
    return CACHED_CONVERTERS
  end
  
  -- Get Windows program files paths
  local programfiles = os.getenv("ProgramFiles") or "C:\\Program Files"
  local programfiles_x86 = os.getenv("ProgramFiles(x86)") or "C:\\Program Files (x86)"
  
  local rsvg_candidates = {
    "rsvg-convert",
    "/opt/homebrew/bin/rsvg-convert", "/usr/local/bin/rsvg-convert", "/usr/bin/rsvg-convert",
    -- Windows paths (Chocolatey typically installs to these locations)
    programfiles .. "\\rsvg-convert\\rsvg-convert.exe",
    "C:\\ProgramData\\chocolatey\\bin\\rsvg-convert.exe"
  }
  local inkscape_candidates = {
    "inkscape",
    "/Applications/Inkscape.app/Contents/MacOS/inkscape",
    "/opt/homebrew/bin/inkscape", "/usr/local/bin/inkscape", "/usr/bin/inkscape",
    -- Windows paths
    programfiles .. "\\Inkscape\\bin\\inkscape.exe",
    programfiles_x86 .. "\\Inkscape\\bin\\inkscape.exe"
  }
  local magick_candidates = {
    "magick", "convert",
    "/opt/homebrew/bin/magick", "/usr/local/bin/magick", "/usr/bin/magick",
    "/opt/homebrew/bin/convert", "/usr/local/bin/convert", "/usr/bin/convert",
    -- Windows paths
    programfiles .. "\\ImageMagick\\magick.exe",
    programfiles .. "\\ImageMagick\\convert.exe",
    "C:\\ProgramData\\chocolatey\\bin\\magick.exe",
    "C:\\ProgramData\\chocolatey\\bin\\convert.exe"
  }
  local pdfunite_candidates = {
    "pdfunite",
    "/opt/homebrew/bin/pdfunite",
    "/usr/local/bin/pdfunite",
    "/usr/bin/pdfunite",
    -- Windows paths (poppler)
    programfiles .. "\\poppler\\Library\\bin\\pdfunite.exe",
    "C:\\ProgramData\\chocolatey\\bin\\pdfunite.exe"
  }
  local pdftk_candidates = {
    "pdftk",
    "/opt/homebrew/bin/pdftk",
    "/usr/local/bin/pdftk",
    "/usr/bin/pdftk",
    -- Windows paths
    programfiles .. "\\PDFtk\\bin\\pdftk.exe",
    programfiles_x86 .. "\\PDFtk Server\\bin\\pdftk.exe",
    "C:\\ProgramData\\chocolatey\\bin\\pdftk.exe"
  }

  local rsvg   = find_cmd(rsvg_candidates)
  local inks   = find_cmd(inkscape_candidates)
  local magick = find_cmd(magick_candidates)
  local pdfunite = find_cmd(pdfunite_candidates)
  local pdftk = find_cmd(pdftk_candidates)

  -- Cache results for future calls
  CACHED_CONVERTERS = {
    rsvg = rsvg,
    inkscape = inks,
    magick = magick,
    pdfunite = pdfunite,
    pdftk = pdftk
  }
  
  return CACHED_CONVERTERS
end

------------------------------------------------------------
-- Startup Dependency Check
------------------------------------------------------------
local function check_dependencies_on_startup()
  -- Skip startup check on Windows to avoid console window flashes
  -- Dependencies will be checked on first PDF export attempt instead
  if IS_WINDOWS then
    return
  end
  
  local tools = detect_converters()
  local missing = {}
  local warnings = {}
  
  -- Check for SVG to PDF converter (at least one required)
  if not tools.rsvg and not tools.inkscape and not tools.magick then
    table.insert(missing, "SVG converter: rsvg-convert, inkscape, or imagemagick")
    table.insert(warnings, "Install rsvg-convert (recommended): brew install librsvg")
  end
  
  -- Check for PDF combiner (required for multi-page reports)
  if not tools.pdfunite and not tools.pdftk then
    table.insert(missing, "PDF combiner: pdfunite or pdftk")
    table.insert(warnings, "Install pdfunite (recommended): brew install poppler")
    table.insert(warnings, "Or install pdftk: brew install pdftk-java")
  end
  
  -- Only show window if dependencies are missing
  if #missing > 0 then
    local tw = TextWindow.new("PacketReporter - Missing Dependencies")
    tw:append("===================================================\n")
    tw:append("  PacketReporter - Missing Dependencies\n")
    tw:append("===================================================\n\n")
    tw:append("The following dependencies are missing:\n\n")
    
    for _, dep in ipairs(missing) do
      tw:append("  ✗ " .. dep .. "\n")
    end
    
    tw:append("\n")
    tw:append("Installation instructions (macOS/Linux):\n\n")
    
    for _, warning in ipairs(warnings) do
      tw:append("  " .. warning .. "\n")
    end
    
    tw:append("\n")
    tw:append("Note: The plugin will still work but PDF export\n")
    tw:append("functionality will be limited or unavailable.\n")
    tw:append("\n")
    tw:append("Close this window to continue using Wireshark.\n")
    tw:append("===================================================\n")
  end
  -- If all dependencies are met, no message is shown
end

------------------------------------------------------------
-- Chart Generation Utilities
------------------------------------------------------------

-- Generate SVG bar chart
local function generate_bar_chart(data, title, x, y, width, height, show_legend)
  local out = {}
  local function add(s) table.insert(out, s) end
  
  if #data == 0 then return "" end
  
  -- Title
  add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#111">%s</text>\n', 
    x, y - 10, xml_escape(title)))
  
  -- Find max value for scaling
  local max_val = 0
  for _, item in ipairs(data) do
    if item.value > max_val then max_val = item.value end
  end
  
  if max_val == 0 then max_val = 1 end
  
  local bar_width = (width - 100) / #data
  local chart_height = height - 60
  local colors = {"#2C7BB6", "#00A6CA", "#00CCBC", "#90EE90", "#FFD700", 
                  "#FF8C42", "#FF6B6B", "#D946EF", "#8B5CF6", "#06B6D4"}
  
  -- Draw bars
  for i, item in ipairs(data) do
    local bar_h = (item.value / max_val) * chart_height
    local bar_x = x + 50 + (i - 1) * bar_width
    local bar_y = y + height - bar_h - 30
    local color = colors[((i - 1) % #colors) + 1]
    
    -- Bar
    add(string.format('<rect x="%.1f" y="%.1f" width="%.1f" height="%.1f" fill="%s" fill-opacity="0.8"/>\n',
      bar_x, bar_y, bar_width * 0.8, bar_h, color))
    
    -- Value label on top
    add(string.format('<text x="%.1f" y="%.1f" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="#333">%s</text>\n',
      bar_x + bar_width * 0.4, bar_y - 5, item.value))
    
    -- X-axis label
    local label = tostring(item.label)
    if #label > 12 then label = label:sub(1, 10) .. ".." end
    add(string.format('<text x="%.1f" y="%d" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="9" fill="#666">%s</text>\n',
      bar_x + bar_width * 0.4, y + height - 10, xml_escape(label)))
  end
  
  -- Y-axis
  add(string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#999" stroke-width="1"/>\n',
    x + 50, y + 10, x + 50, y + height - 30))
  
  -- X-axis
  add(string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#999" stroke-width="1"/>\n',
    x + 50, y + height - 30, x + width, y + height - 30))
  
  return table.concat(out)
end

-- Generate SVG pie chart
local function generate_pie_chart(data, title, cx, cy, radius, show_legend)
  local out = {}
  local function add(s) table.insert(out, s) end
  
  if #data == 0 then return "" end
  
  -- Title
  add(string.format('<text x="%d" y="%d" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#111">%s</text>\n', 
    cx, cy - radius - 20, xml_escape(title)))
  
  -- Calculate total
  local total = 0
  for _, item in ipairs(data) do
    total = total + item.value
  end
  
  if total == 0 then total = 1 end
  
  local colors = {"#2C7BB6", "#00A6CA", "#00CCBC", "#90EE90", "#FFD700", 
                  "#FF8C42", "#FF6B6B", "#D946EF", "#8B5CF6", "#06B6D4"}
  
  -- Draw slices
  local start_angle = -90  -- Start at top
  for i, item in ipairs(data) do
    local angle = (item.value / total) * 360
    local end_angle = start_angle + angle
    
    -- Calculate slice path
    local start_rad = math.rad(start_angle)
    local end_rad = math.rad(end_angle)
    local x1 = cx + radius * math.cos(start_rad)
    local y1 = cy + radius * math.sin(start_rad)
    local x2 = cx + radius * math.cos(end_rad)
    local y2 = cy + radius * math.sin(end_rad)
    
    local large_arc = angle > 180 and 1 or 0
    local color = colors[((i - 1) % #colors) + 1]
    
    local path = string.format('M %d %d L %.2f %.2f A %d %d 0 %d 1 %.2f %.2f Z',
      cx, cy, x1, y1, radius, radius, large_arc, x2, y2)
    
    add(string.format('<path d="%s" fill="%s" fill-opacity="0.8" stroke="white" stroke-width="2"/>\n',
      path, color))
    
    -- Add percentage label on slice if significant
    if angle > 15 then
      local mid_angle = math.rad(start_angle + angle / 2)
      local label_x = cx + (radius * 0.7) * math.cos(mid_angle)
      local label_y = cy + (radius * 0.7) * math.sin(mid_angle)
      local pct = string.format("%.1f%%", (item.value / total) * 100)
      
      add(string.format('<text x="%.1f" y="%.1f" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="11" font-weight="700" fill="white">%s</text>\n',
        label_x, label_y + 4, pct))
    end
    
    start_angle = end_angle
  end
  
  -- Legend
  if show_legend then
    local legend_x = cx + radius + 30
    local legend_y = cy - radius
    
    for i, item in ipairs(data) do
      local y = legend_y + (i - 1) * 22
      local color = colors[((i - 1) % #colors) + 1]
      
      -- Color box
      add(string.format('<rect x="%d" y="%d" width="14" height="14" fill="%s"/>\n',
        legend_x, y - 10, color))
      
      -- Label
      local label = tostring(item.label)
      if #label > 20 then label = label:sub(1, 18) .. ".." end
      add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#333">%s (%d)</text>\n',
        legend_x + 20, y + 2, xml_escape(label), item.value))
    end
  end
  
  return table.concat(out)
end

-- Generate SVG table
local function generate_table(data, title, x, y, width, columns)
  local out = {}
  local function add(s) table.insert(out, s) end
  
  if #data == 0 then return "", 0 end
  
  -- Title
  add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#111">%s</text>\n', 
    x, y - 10, xml_escape(title)))
  
  -- Calculate column widths with custom sizing support
  -- For number columns (rank, count, queries, requests, connections, packets), use fixed small width (~40-60px)
  -- Give remaining space to text columns
  local number_fields = {"rank", "count", "queries", "requests", "connections", "packets"}
  local fixed_width = 60  -- Fixed width for number columns (supports 6 digits)
  local num_number_cols = 0
  local num_text_cols = 0
  
  for _, col in ipairs(columns) do
    local is_number = false
    for _, nf in ipairs(number_fields) do
      if col.field == nf then
        is_number = true
        break
      end
    end
    if is_number then
      num_number_cols = num_number_cols + 1
    else
      num_text_cols = num_text_cols + 1
    end
  end
  
  -- Calculate remaining width for text columns
  local remaining_width = width - 20 - (num_number_cols * fixed_width)
  local text_col_width = num_text_cols > 0 and (remaining_width / num_text_cols) or 0
  
  -- Create column width mapping
  local col_widths = {}
  for i, col in ipairs(columns) do
    local is_number = false
    for _, nf in ipairs(number_fields) do
      if col.field == nf then
        is_number = true
        break
      end
    end
    col_widths[i] = is_number and fixed_width or text_col_width
  end
  
  local row_height = 22
  local header_y = y + 10
  
  -- Header background
  add(string.format('<rect x="%d" y="%d" width="%d" height="%d" fill="#e8f4f8" stroke="#2C7BB6" stroke-width="1"/>\n',
    x, y, width, row_height))
  
  -- Header text
  local cumulative_x = 0
  for i, col in ipairs(columns) do
    local col_x = x + 10 + cumulative_x
    add(string.format('<text x="%.0f" y="%.0f" font-family="Arial, Helvetica, sans-serif" font-size="11" font-weight="700" fill="#111" dominant-baseline="middle">%s</text>\n',
      col_x, y + row_height / 2, xml_escape(col.title)))
    cumulative_x = cumulative_x + col_widths[i]
  end
  
  -- Data rows
  for row_idx, row_data in ipairs(data) do
    local row_y = y + row_idx * row_height
    
    -- Alternating row background
    if row_idx % 2 == 0 then
      add(string.format('<rect x="%d" y="%d" width="%d" height="%d" fill="#f9f9f9"/>\n',
        x, row_y, width, row_height))
    end
    
    -- Row border
    add(string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#ddd" stroke-width="0.5"/>\n',
      x, row_y, x + width, row_y))
    
    -- Cell data
    cumulative_x = 0
    for i, col in ipairs(columns) do
      local col_x = x + 10 + cumulative_x
      local value = row_data[col.field] or ""
      
      -- Truncate if too long
      value = tostring(value)
      local max_len = math.floor(col_widths[i] / 6.5)
      if #value > max_len then
        value = value:sub(1, max_len - 2) .. ".."
      end
      
      add(string.format('<text x="%.0f" y="%.0f" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="#333">%s</text>\n',
        col_x, row_y + 14, xml_escape(value)))
      
      cumulative_x = cumulative_x + col_widths[i]
    end
  end
  
  -- Bottom border
  local bottom_y = y + (#data + 1) * row_height
  add(string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="#2C7BB6" stroke-width="1"/>\n',
    x, bottom_y, x + width, bottom_y))
  
  local total_height = (#data + 1) * row_height + 10
  return table.concat(out), total_height
end

------------------------------------------------------------
-- Page Boundary Helper Function
------------------------------------------------------------
local function check_page_boundary(y_pos, required_space, paper, add_func)
  local bottom_margin = 60
  local page_usable_height = paper.height - bottom_margin
  local current_page_num = math.floor(y_pos / paper.height)
  local space_on_page = page_usable_height - (y_pos - (current_page_num * paper.height))
  
  -- If not enough space on current page, move to next page
  if space_on_page < required_space then
    local padding = paper.height - (y_pos - (current_page_num * paper.height))
    add_func(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
    return y_pos + padding + 80  -- Return new y_pos on next page with margin
  end
  
  return y_pos  -- Return unchanged y_pos
end

------------------------------------------------------------
-- Multi-page PDF Export Function
------------------------------------------------------------
local function get_reports_directory()
  local home = get_home_dir()
  local sep = IS_WINDOWS and "\\" or "/"
  local docs_dir = home .. sep .. "Documents"
  local reports_dir = docs_dir .. sep .. "PacketReporter Reports"
  
  -- Try to create the reports directory (mkdir will succeed if Documents exists)
  if IS_WINDOWS then
    -- On Windows, use silent PowerShell to avoid console window
    run_silent('if (!(Test-Path "' .. reports_dir:gsub("\\", "/") .. '")) { New-Item -ItemType Directory -Path "' .. reports_dir:gsub("\\", "/") .. '" -Force | Out-Null }')
  else
    -- On Unix, use mkdir -p
    os.execute('mkdir -p "' .. reports_dir .. '" 2>/dev/null')
  end
  
  -- Test if the directory was created successfully by trying to create a test file
  local test_file = reports_dir .. sep .. ".test"
  local f = io.open(test_file, "w")
  if f then
    f:close()
    os.remove(test_file)
    return reports_dir
  end
  
  -- If that failed, fall back to home directory
  return home
end

local function open_pdf_with_default_app(pdf_path)
  if IS_WINDOWS then
    -- On Windows, use PowerShell Start-Process with literal path
    local ps_path = pdf_path:gsub("\\", "\\\\")
    local ps_cmd = string.format('powershell.exe -WindowStyle Hidden -Command "Start-Process -FilePath \'%s\'"', ps_path)
    local rc = os.execute(ps_cmd)
    return rc == true or rc == 0
  else
    -- On macOS/Linux, use 'open' or 'xdg-open'
    local cmd = 'open "' .. pdf_path .. '"'
    if not run_sh(cmd) then
      cmd = 'xdg-open "' .. pdf_path .. '"'
      return run_sh(cmd)
    end
    return true
  end
end

-- Simple single-page PDF export for Summary Report
local function export_single_page_pdf(svg_path, tw, tools, paper_size)
  local reports_dir = get_reports_directory()
  local stamp = os.date("%Y%m%d-%H%M%S")
  local sep = IS_WINDOWS and "\\" or "/"
  local pdf_path = reports_dir .. sep .. "PacketReporterSummary-" .. stamp .. ".pdf"
  
  tw:append("Exporting PDF...\n")
  
  if tools.rsvg then
    local cmd = string.format('%s -f pdf -o "%s" "%s" 2>&1', tools.rsvg, pdf_path, svg_path)
    local handle = IS_WINDOWS and popen_silent(cmd, "r") or io.popen(cmd)
    local result = handle:read("*a")
    local success = handle:close()
    
    if success then
      tw:append("✓ PDF exported: " .. pdf_path .. "\n")
      if open_pdf_with_default_app(pdf_path) then
        tw:append("✓ PDF opened successfully\n")
      end
      return pdf_path
    else
      tw:append("✗ rsvg-convert failed\n")
    end
  end
  
  
  if tools.inkscape then
    local cmd
    if IS_WINDOWS then
      cmd = '"' .. tools.inkscape .. '" "' .. svg_path .. '" --export-type=pdf --export-filename="' .. pdf_path .. '"'
    else
      cmd = "sh -c '\"" .. tools.inkscape .. "\" \"" .. svg_path .. "\" --export-type=pdf --export-filename=\"" .. pdf_path .. "\"'"
    end
    if run_sh(cmd) then
      tw:append("✓ PDF exported: " .. pdf_path .. "\n")
      if open_pdf_with_default_app(pdf_path) then
        tw:append("✓ PDF opened successfully\n")
      end
      return pdf_path
    end
  end
  
  tw:append("✗ PDF export failed - no converter available\n")
  return nil
end

local function export_multipage_pdf(svg_content, total_height, tw, tools, paper_size)
  local reports_dir = get_reports_directory()
  local stamp = os.date("%Y%m%d-%H%M%S")
  local sep = IS_WINDOWS and "\\" or "/"
  local pdf_path = reports_dir .. sep .. "PacketReport-" .. stamp .. ".pdf"
  
  tw:append("Attempting multi-page PDF export...\n")
  tw:append("Reports directory: " .. reports_dir .. "\n")
  
  -- Check dependencies - only report if all met, otherwise show what's missing
  local has_converter = tools.rsvg or tools.inkscape or tools.magick
  local has_combiner = tools.pdfunite or tools.pdftk
  if not has_converter or not has_combiner then
    tw:append("\n✗ Missing dependencies:\n")
    if not has_converter then
      tw:append("  - SVG converter: rsvg-convert, inkscape, or imagemagick\n")
      tw:append("    Install: brew install librsvg (recommended)\n")
    end
    if not has_combiner then
      tw:append("  - PDF combiner: pdfunite or pdftk\n")
      tw:append("    Install: brew install poppler (pdfunite) or pdftk-java\n")
    end
    tw:append("\nPDF export cannot proceed without these dependencies.\n")
    return nil
  end
  tw:append("\n✓ All dependencies met - proceeding with PDF export\n")
  
  local paper = paper_size == "Legal" and PAPER_SIZES.LEGAL or PAPER_SIZES.A4
  local num_pages = math.ceil(total_height / paper.height)
  tw:append(string.format("  Creating %d pages (page size: %s, %dx%dpx)\n", num_pages, paper.name, paper.width, paper.height))
  
  -- Read configuration files and generate cover page
  tw:append("Generating cover page...\n")
  local config = read_config_files()
  
  -- Define TOC items with estimated page numbers
  local toc_items = {
    {title = "1. PCAP File Summary", page = 2},
    {title = "2. Top 10 IP Addresses", page = 2},
    {title = "3. Protocol Distribution", page = 3},
    {title = "4. IP Communication Matrix", page = 3},
    {title = "5. Port Analysis", page = 4},
    {title = "6. DNS Analysis", page = 5},
    {title = "7. TLS/SSL Analysis", page = 7},
    {title = "8. HTTP Analysis", page = 8},
    {title = "9. MAC Layer Analysis", page = 9},
    {title = "10. IP Layer Analysis", page = 10},
    {title = "11. TCP Analysis", page = 11}
  }
  
  local cover_page_svg = generate_cover_page(paper, config, toc_items)
  
  -- Save cover page SVG
  local cover_svg_path = os.tmpname() .. "_cover.svg"
  local fh = io.open(cover_svg_path, "wb")
  if fh then
    fh:write(cover_page_svg)
    fh:close()
    tw:append("  ✓ Cover page created\n")
  else
    tw:append("  ⚠ Failed to create cover page, continuing without it\n")
    cover_svg_path = nil
  end
  
  -- Create separate SVG for each page
  local page_svgs = {}
  
  -- Add cover page as first page if it was created successfully
  if cover_svg_path then
    table.insert(page_svgs, cover_svg_path)
  end
  
  -- Create content pages (starting from page 2 if cover exists)
  for page_num = 1, num_pages do
    local page_y_start = (page_num - 1) * paper.height
    
    -- Create complete SVG with content shifted up to show the correct page
    local page_svg = string.format(
      '<?xml version="1.0" encoding="UTF-8"?>\n' ..
      '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n' ..
      '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="%d" height="%d">\n' ..
      '<g transform="translate(0, %d)">\n',
      paper.width, paper.height, -page_y_start)
    
    -- Add the original content (shifted to show this page)
    page_svg = page_svg .. svg_content .. '</g>\n</svg>\n'
    
    -- Save page SVG
    local page_svg_path = os.tmpname() .. "_page" .. page_num .. ".svg"
    local fh = io.open(page_svg_path, "wb")
    if fh then
      fh:write(page_svg)
      fh:close()
      table.insert(page_svgs, page_svg_path)
      local display_page = cover_svg_path and (page_num + 1) or page_num
      local display_total = cover_svg_path and (num_pages + 1) or num_pages
      tw:append(string.format("  Created page %d/%d\n", display_page, display_total))
    else
      tw:append(string.format("✗ Failed to create page %d\n", page_num))
      return nil
    end
  end
  
  -- Convert each SVG to PDF
  local page_pdfs = {}

  if tools.rsvg then
    tw:append("Converting pages to PDF (this may take a moment)...\n")
    local total_pages = #page_svgs
    
    -- On Windows, batch all conversions into single VBScript call
    if IS_WINDOWS then
      local page_pdf_paths = {}
      
      -- Build batch file with ALL conversion commands
      local bat_path = os.tmpname() .. ".bat"
      local f = io.open(bat_path, "w")
      if f then
        f:write("@echo off\n")
        
        -- Add all conversion commands to batch file
        for i, svg_path in ipairs(page_svgs) do
          local page_pdf_path = os.tmpname() .. "_page" .. i .. ".pdf"
          page_pdf_paths[i] = page_pdf_path
          f:write(string.format('"%s" -f pdf -o "%s" "%s"\n', tools.rsvg, page_pdf_path, svg_path))
        end
        f:close()
        
        -- Create VBScript to run batch file silently
        local vbs_path = os.tmpname() .. ".vbs"
        local vbs_content = string.format([[
Set objShell = CreateObject("WScript.Shell")
returnCode = objShell.Run("%s", 0, True)
WScript.Quit returnCode
]], bat_path:gsub("\\", "\\\\"))
        
        f = io.open(vbs_path, "w")
        if f then
          f:write(vbs_content)
          f:close()
          
          -- Execute VBScript once for all conversions (single console window suppressed)
          os.execute('cscript.exe //Nologo "' .. vbs_path .. '" >NUL 2>&1')
          
          -- Clean up
          os.remove(vbs_path)
          os.remove(bat_path)
        else
          os.remove(bat_path)
        end
      end
      
      -- Check which PDFs were created
      for i, page_pdf_path in ipairs(page_pdf_paths) do
        local pdf_test = io.open(page_pdf_path, "r")
        if pdf_test then
          pdf_test:close()
          table.insert(page_pdfs, page_pdf_path)
        else
          tw:append(string.format("  ✗ Failed to convert page %d\n", i))
        end
      end
    else
      -- Unix: convert pages individually
      for i, svg_path in ipairs(page_svgs) do
        local page_pdf_path = os.tmpname() .. "_page" .. i .. ".pdf"
        local cmd = string.format('%s -f pdf -o "%s" "%s" 2>&1', tools.rsvg, page_pdf_path, svg_path)
        local handle = io.popen(cmd)
        local result = handle:read("*a")
        local success = handle:close()
        
        -- Check if PDF was actually created (more reliable than checking return code)
        local pdf_test = io.open(page_pdf_path, "r")
        if pdf_test then
          pdf_test:close()
          table.insert(page_pdfs, page_pdf_path)
        else
          tw:append(string.format("  ✗ Failed to convert page %d\n", i))
          if result and result ~= "" then
            tw:append("    Error: " .. result:sub(1, 200) .. "\n")
          end
          if not success then
            tw:append("    Command failed to execute\n")
          end
        end
      end
    end
    tw:append(string.format("  ✓ Converted %d pages to PDF\n", #page_pdfs))
    
    local expected_page_count = cover_svg_path and (num_pages + 1) or num_pages
    if #page_pdfs == expected_page_count then
      -- Combine PDFs using pdftk or pdfunite
      tw:append("Combining pages into single PDF...\n")
      
      -- Build quoted list of PDF paths
      local pdf_list_parts = {}
      for _, pdf in ipairs(page_pdfs) do
        if IS_WINDOWS then
          -- Convert to forward slashes for better Windows compatibility
          table.insert(pdf_list_parts, '"' .. pdf:gsub("\\", "/") .. '"')
        else
          table.insert(pdf_list_parts, '"' .. pdf .. '"')
        end
      end
      local pdf_list = table.concat(pdf_list_parts, ' ')
      
      local success = false
      local result = ""
      
      if tools.pdfunite then
        tw:append("  Using pdfunite: " .. tools.pdfunite .. "\n")
        
        if IS_WINDOWS then
          -- Use VBScript for silent execution on Windows
          local combine_cmd = string.format('%s %s "%s"', tools.pdfunite, pdf_list, pdf_path)
          success = run_vbs_silent(combine_cmd)
          result = ""  -- VBScript doesn't capture output
        else
          local combine_cmd = string.format('%s %s "%s" 2>&1', tools.pdfunite, pdf_list, pdf_path)
          local handle = io.popen(combine_cmd)
          result = handle:read("*a")
          success = handle:close()
        end
      elseif tools.pdftk then
        tw:append("  Using pdftk: " .. tools.pdftk .. "\n")
        
        if IS_WINDOWS then
          -- Use VBScript for silent execution on Windows
          local combine_cmd = string.format('%s %s cat output "%s"', tools.pdftk, pdf_list, pdf_path)
          success = run_vbs_silent(combine_cmd)
          result = ""
        else
          local combine_cmd = string.format('%s %s cat output "%s" 2>&1', tools.pdftk, pdf_list, pdf_path)
          local handle = io.popen(combine_cmd)
          result = handle:read("*a")
          success = handle:close()
        end
      end
      
      -- Check if output PDF was actually created (more reliable than exit code)
      local pdf_created = false
      local test_file = io.open(pdf_path, "r")
      if test_file then
        test_file:close()
        pdf_created = true
        success = true  -- Override success if file exists
      end
      
      -- Clean up individual page PDFs
      for _, pdf in ipairs(page_pdfs) do
        os.remove(pdf)
      end
      
      if success and pdf_created then
        local total_pages_display = cover_svg_path and (num_pages + 1) or num_pages
        tw:append("✓ Created multi-page PDF: " .. pdf_path .. "\n")
        tw:append(string.format("  Total pages: %d\n", total_pages_display))
        
        -- Open PDF with default application
        tw:append("Opening PDF...\n")
        if open_pdf_with_default_app(pdf_path) then
          tw:append("✓ PDF opened successfully\n")
        else
          tw:append("⚠ Could not auto-open PDF. Please open manually.\n")
        end
        
        return pdf_path
      else
        tw:append("✗ Failed to combine PDFs\n")
        tw:append("  Error: " .. (result or "unknown") .. "\n")
        tw:append("  Install 'pdfunite' (poppler-utils) or 'pdftk' to combine pages\n")
        return nil
      end
    else
      tw:append("✗ Not all pages were converted successfully\n")
      return nil
    end
  end
  
  -- If rsvg not available, inkscape and imagemagick cannot be used for multi-page PDFs
  -- as they don't support the same workflow
  tw:append("✗ PDF export not available (rsvg-convert required for multi-page PDFs).\n")
  tw:append("  Install rsvg-convert (recommended): brew install librsvg (macOS)\n")
  tw:append("  Or: choco install rsvg-convert (Windows)\n")
  tw:append("  Or: sudo apt install librsvg2-bin (Linux)\n")
  return nil
end

------------------------------------------------------------
-- Data Collection Functions
------------------------------------------------------------

-- Collect basic statistics
local function collect_basic_stats()
  local stats = {
    total_packets = 0,
    total_bytes = 0,
    ip_addresses = {},
    protocols = {},
    tcp_ports = {},
    udp_ports = {},
    start_time = nil,
    end_time = nil
  }
  
  local tap = Listener.new("frame", nil)
  
  function tap.packet(pinfo, tvb)
    stats.total_packets = stats.total_packets + 1
    
    local frame_len = f2n(f_frame_len) or 0
    stats.total_bytes = stats.total_bytes + frame_len
    
    local frame_time = f2n(f_frame_time)
    if frame_time then
      if not stats.start_time or frame_time < stats.start_time then
        stats.start_time = frame_time
      end
      if not stats.end_time or frame_time > stats.end_time then
        stats.end_time = frame_time
      end
    end
    
    -- Collect IP addresses
    local src_ip = f2s(f_ip_src) or f2s(f_ip6_src)
    local dst_ip = f2s(f_ip_dst) or f2s(f_ip6_dst)
    if src_ip then
      stats.ip_addresses[src_ip] = (stats.ip_addresses[src_ip] or 0) + 1
    end
    if dst_ip then
      stats.ip_addresses[dst_ip] = (stats.ip_addresses[dst_ip] or 0) + 1
    end
    
    -- Collect protocols
    local protocols = f2s(f_frame_protocols) or ""
    local proto = protocols:match("([^:]+)$") or ""
    if proto ~= "" then
      stats.protocols[proto] = (stats.protocols[proto] or 0) + 1
    end
    
    -- Collect ports
    local tcp_sport = f2n(f_tcp_srcport)
    local tcp_dport = f2n(f_tcp_dstport)
    local udp_sport = f2n(f_udp_srcport)
    local udp_dport = f2n(f_udp_dstport)
    
    if tcp_sport then stats.tcp_ports[tcp_sport] = (stats.tcp_ports[tcp_sport] or 0) + 1 end
    if tcp_dport then stats.tcp_ports[tcp_dport] = (stats.tcp_ports[tcp_dport] or 0) + 1 end
    if udp_sport then stats.udp_ports[udp_sport] = (stats.udp_ports[udp_sport] or 0) + 1 end
    if udp_dport then stats.udp_ports[udp_dport] = (stats.udp_ports[udp_dport] or 0) + 1 end
  end
  
  retap_packets()
  tap:remove()
  
  return stats
end

-- Collect DNS statistics
local function collect_dns_stats()
  local stats = {
    queries = {},
    answers = {},
    ips = {},
    record_types = {},
    authoritative = 0,
    non_authoritative = 0,
    total_queries = 0,
    total_responses = 0
  }
  
  local tap = Listener.new("dns", nil)
  
  function tap.packet(pinfo, tvb)
    -- Check if this is a query or response
    local is_response = f2n(f_dns_flags_response)
    
    if is_response == 0 or not is_response then
      -- This is a query
      stats.total_queries = stats.total_queries + 1
      
      local qry = f2s(f_dns_qry_name)
      if qry then
        stats.queries[qry] = (stats.queries[qry] or 0) + 1
      end
      
      -- Record type
      local qry_type = f2n(f_dns_qry_type)
      if qry_type then
        local type_name = ""
        if qry_type == 1 then type_name = "A"
        elseif qry_type == 2 then type_name = "NS"
        elseif qry_type == 5 then type_name = "CNAME"
        elseif qry_type == 6 then type_name = "SOA"
        elseif qry_type == 12 then type_name = "PTR"
        elseif qry_type == 15 then type_name = "MX"
        elseif qry_type == 16 then type_name = "TXT"
        elseif qry_type == 28 then type_name = "AAAA"
        elseif qry_type == 33 then type_name = "SRV"
        elseif qry_type == 255 then type_name = "ANY"
        else type_name = string.format("Type %d", qry_type) end
        stats.record_types[type_name] = (stats.record_types[type_name] or 0) + 1
      end
    else
      -- This is a response
      stats.total_responses = stats.total_responses + 1
      
      -- Check if authoritative
      local is_auth = f2n(f_dns_flags_authoritative)
      if is_auth == 1 then
        stats.authoritative = stats.authoritative + 1
      else
        stats.non_authoritative = stats.non_authoritative + 1
      end
      
      local resp = f2s(f_dns_resp_name)
      if resp then
        stats.answers[resp] = (stats.answers[resp] or 0) + 1
      end
      
      local a_ip = f2s(f_dns_a)
      if a_ip then
        stats.ips[a_ip] = (stats.ips[a_ip] or 0) + 1
      end
      
      local aaaa_ip = f2s(f_dns_aaaa)
      if aaaa_ip then
        stats.ips[aaaa_ip] = (stats.ips[aaaa_ip] or 0) + 1
      end
    end
  end
  
  retap_packets()
  tap:remove()
  
  return stats
end

-- Collect HTTP statistics
local function collect_http_stats()
  local stats = {
    user_agents = {},
    hosts = {},
    servers = {},
    content_types = {},
    status_codes = {}
  }
  
  local tap = Listener.new("http", nil)
  
  function tap.packet(pinfo, tvb)
    local ua = f2s(f_http_user_agent)
    if ua then
      stats.user_agents[ua] = (stats.user_agents[ua] or 0) + 1
    end
    
    local host = f2s(f_http_host)
    if host then
      stats.hosts[host] = (stats.hosts[host] or 0) + 1
    end
    
    local server = f2s(f_http_server)
    if server then
      stats.servers[server] = (stats.servers[server] or 0) + 1
    end
    
    local ct = f2s(f_http_content_type)
    if ct then
      stats.content_types[ct] = (stats.content_types[ct] or 0) + 1
    end
    
    local code = f2n(f_http_response_code)
    if code then
      stats.status_codes[tostring(code)] = (stats.status_codes[tostring(code)] or 0) + 1
    end
  end
  
  retap_packets()
  tap:remove()
  
  return stats
end

-- Collect MAC layer statistics (Phase 2)
local function collect_mac_stats()
  local stats = {
    frame_sizes = {},
    broadcast = 0,
    multicast = 0,
    unicast = 0,
    vendors = {}
  }
  
  local tap = Listener.new("frame", nil)
  
  function tap.packet(pinfo, tvb)
    -- Frame size distribution
    local frame_len = f2n(f_frame_len) or 0
    local size_bucket = ""
    if frame_len <= 64 then size_bucket = "0-64"
    elseif frame_len <= 128 then size_bucket = "65-128"
    elseif frame_len <= 256 then size_bucket = "129-256"
    elseif frame_len <= 512 then size_bucket = "257-512"
    elseif frame_len <= 1024 then size_bucket = "513-1024"
    elseif frame_len <= 1518 then size_bucket = "1025-1518"
    else size_bucket = "1519+" end
    stats.frame_sizes[size_bucket] = (stats.frame_sizes[size_bucket] or 0) + 1
    
    -- Broadcast/Multicast/Unicast
    local dst_type = f2n(f_eth_dst_type)
    if dst_type == 0 then
      stats.unicast = stats.unicast + 1
    elseif dst_type == 1 then
      stats.broadcast = stats.broadcast + 1
    elseif dst_type == 2 then
      stats.multicast = stats.multicast + 1
    end
    
    -- Vendor information
    local vendor = f2s(f_eth_src_oui)
    if vendor then
      local vendor_name = vendor:match("%((.+)%)$") or vendor
      stats.vendors[vendor_name] = (stats.vendors[vendor_name] or 0) + 1
    end
  end
  
  retap_packets()
  tap:remove()
  
  return stats
end

-- Collect IP layer statistics (Phase 2)
local function collect_ip_stats()
  local stats = {
    ttl = {},
    fragmented = 0,
    total_packets = 0,
    dscp = {},
    protocols = {}
  }
  
  local tap = Listener.new("ip", nil)
  
  function tap.packet(pinfo, tvb)
    stats.total_packets = stats.total_packets + 1
    
    -- TTL distribution
    local ttl = f2n(f_ip_ttl)
    if ttl then
      local ttl_bucket = ""
      if ttl <= 32 then ttl_bucket = "0-32"
      elseif ttl <= 64 then ttl_bucket = "33-64"
      elseif ttl <= 96 then ttl_bucket = "65-96"
      elseif ttl <= 128 then ttl_bucket = "97-128"
      elseif ttl <= 160 then ttl_bucket = "129-160"
      elseif ttl <= 192 then ttl_bucket = "161-192"
      elseif ttl <= 224 then ttl_bucket = "193-224"
      else ttl_bucket = "225-255" end
      stats.ttl[ttl_bucket] = (stats.ttl[ttl_bucket] or 0) + 1
    end
    
    -- Fragmentation
    local mf = f2n(f_ip_flags_mf)
    local offset = f2n(f_ip_frag_offset)
    if (mf and mf == 1) or (offset and offset > 0) then
      stats.fragmented = stats.fragmented + 1
    end
    
    -- DSCP (Differentiated Services)
    local dscp = f2n(f_ip_dsfield)
    if dscp then
      -- Extract DSCP value (upper 6 bits)
      local dscp_val = math.floor(dscp / 4)
      local dscp_name = ""
      if dscp_val == 0 then dscp_name = "Best Effort (0)"
      elseif dscp_val == 8 then dscp_name = "CS1 (8)"
      elseif dscp_val == 10 then dscp_name = "AF11 (10)"
      elseif dscp_val == 12 then dscp_name = "AF12 (12)"
      elseif dscp_val == 14 then dscp_name = "AF13 (14)"
      elseif dscp_val == 16 then dscp_name = "CS2 (16)"
      elseif dscp_val == 18 then dscp_name = "AF21 (18)"
      elseif dscp_val == 20 then dscp_name = "AF22 (20)"
      elseif dscp_val == 22 then dscp_name = "AF23 (22)"
      elseif dscp_val == 24 then dscp_name = "CS3 (24)"
      elseif dscp_val == 26 then dscp_name = "AF31 (26)"
      elseif dscp_val == 28 then dscp_name = "AF32 (28)"
      elseif dscp_val == 30 then dscp_name = "AF33 (30)"
      elseif dscp_val == 32 then dscp_name = "CS4 (32)"
      elseif dscp_val == 34 then dscp_name = "AF41 (34)"
      elseif dscp_val == 36 then dscp_name = "AF42 (36)"
      elseif dscp_val == 38 then dscp_name = "AF43 (38)"
      elseif dscp_val == 40 then dscp_name = "CS5 (40)"
      elseif dscp_val == 46 then dscp_name = "EF (46)"
      elseif dscp_val == 48 then dscp_name = "CS6 (48)"
      elseif dscp_val == 56 then dscp_name = "CS7 (56)"
      else dscp_name = string.format("DSCP %d", dscp_val) end
      stats.dscp[dscp_name] = (stats.dscp[dscp_name] or 0) + 1
    end
    
    -- IP Protocol
    local proto = f2n(f_ip_proto)
    if proto then
      local proto_name = ""
      if proto == 1 then proto_name = "ICMP"
      elseif proto == 2 then proto_name = "IGMP"
      elseif proto == 6 then proto_name = "TCP"
      elseif proto == 17 then proto_name = "UDP"
      elseif proto == 41 then proto_name = "IPv6"
      elseif proto == 47 then proto_name = "GRE"
      elseif proto == 50 then proto_name = "ESP"
      elseif proto == 51 then proto_name = "AH"
      elseif proto == 58 then proto_name = "ICMPv6"
      elseif proto == 89 then proto_name = "OSPF"
      elseif proto == 132 then proto_name = "SCTP"
      else proto_name = string.format("Protocol %d", proto) end
      stats.protocols[proto_name] = (stats.protocols[proto_name] or 0) + 1
    end
  end
  
  retap_packets()
  tap:remove()
  
  return stats
end

-- Collect TCP layer statistics (Phase 2)
local function collect_tcp_stats()
  local stats = {
    window_sizes = {},
    segment_sizes = {},
    rtt_samples = {},
    total_packets = 0
  }
  
  local tap = Listener.new("tcp", nil)
  
  function tap.packet(pinfo, tvb)
    stats.total_packets = stats.total_packets + 1
    
    -- Window size distribution
    local window = f2n(f_tcp_window_size)
    if window then
      local win_bucket = ""
      if window == 0 then win_bucket = "0"
      elseif window <= 8192 then win_bucket = "1-8K"
      elseif window <= 16384 then win_bucket = "8K-16K"
      elseif window <= 32768 then win_bucket = "16K-32K"
      elseif window <= 65535 then win_bucket = "32K-64K"
      else win_bucket = "64K+" end
      stats.window_sizes[win_bucket] = (stats.window_sizes[win_bucket] or 0) + 1
    end
    
    -- Segment size distribution
    local seg_len = f2n(f_tcp_len)
    if seg_len and seg_len > 0 then
      local seg_bucket = ""
      if seg_len <= 64 then seg_bucket = "1-64"
      elseif seg_len <= 256 then seg_bucket = "65-256"
      elseif seg_len <= 512 then seg_bucket = "257-512"
      elseif seg_len <= 1024 then seg_bucket = "513-1024"
      elseif seg_len <= 1460 then seg_bucket = "1025-1460"
      else seg_bucket = "1460+" end
      stats.segment_sizes[seg_bucket] = (stats.segment_sizes[seg_bucket] or 0) + 1
    end
    
    -- RTT samples
    local rtt = f2n(f_tcp_analysis_ack_rtt)
    if rtt then
      local rtt_ms = rtt * 1000
      local rtt_bucket = ""
      if rtt_ms < 1 then rtt_bucket = "<1ms"
      elseif rtt_ms <= 10 then rtt_bucket = "1-10ms"
      elseif rtt_ms <= 50 then rtt_bucket = "10-50ms"
      elseif rtt_ms <= 100 then rtt_bucket = "50-100ms"
      elseif rtt_ms <= 500 then rtt_bucket = "100-500ms"
      else rtt_bucket = "500ms+" end
      stats.rtt_samples[rtt_bucket] = (stats.rtt_samples[rtt_bucket] or 0) + 1
    end
  end
  
  retap_packets()
  tap:remove()
  
  return stats
end

-- Collect TLS/SSL and QUIC statistics
local function collect_tls_stats()
  local stats = {
    versions = {},
    sni_names = {},
    cipher_suites = {},
    cert_common_names = {},
    quic_count = 0,
    total_connections = 0
  }
  
  -- Try multiple protocol names: frame (to catch all), ssl, tls
  local tap = nil
  local tap_name = nil
  
  -- Use frame tap and filter for TLS/SSL in the packet processing
  local ok, err = pcall(function()
    tap = Listener.new("frame", nil)
    tap_name = "frame"
  end)
  
  -- If frame tap fails, return empty stats
  if not ok or not tap then
    return stats
  end
  
  local packet_count = 0
  local tls_packet_count = 0
  
  function tap.packet(pinfo, tvb)
    packet_count = packet_count + 1
    
    -- Check if this packet contains TLS/SSL or QUIC by looking at protocols
    local protocols = f2s(f_frame_protocols)
    if not protocols then return end
    
    local protocols_lower = protocols:lower()
    
    -- Also try to get protocol from pinfo (more reliable for TLS version)
    local pinfo_protocol = ""
    local pinfo_protocol_orig = ""
    if pinfo and pinfo.cols and pinfo.cols.protocol then
      pinfo_protocol_orig = tostring(pinfo.cols.protocol)
      pinfo_protocol = pinfo_protocol_orig:lower()
    end
    
    -- Also try to get the actual protocol name from the dissection tree
    -- This is what Wireshark displays in the protocol column
    local protocol_name = ""
    if pinfo and pinfo.cols and pinfo.cols.protocol then
      protocol_name = tostring(pinfo.cols.protocol)
    end
    
    -- Check for QUIC first (before TLS check)
    local is_quic = false
    if protocols_lower:find("quic") then
      is_quic = true
      stats.quic_count = stats.quic_count + 1
      -- QUIC uses TLS 1.3, so count it as TLS 1.3
      stats.versions["TLS 1.3"] = (stats.versions["TLS 1.3"] or 0) + 1
      return
    end
    
    -- Check for UDP port 443 (potential QUIC)
    local udp_dst = f2n(f_udp_dstport)
    local udp_src = f2n(f_udp_srcport)
    if (udp_dst == 443 or udp_src == 443) and not (protocols_lower:find("ssl") or protocols_lower:find("tls")) then
      -- UDP 443 without TLS/SSL might be QUIC
      if protocols_lower:find("udp") then
        stats.quic_count = stats.quic_count + 1
        stats.versions["QUIC"] = (stats.versions["QUIC"] or 0) + 1
        return
      end
    end
    
    -- Check for ssl or tls in the protocol stack
    if not (protocols_lower:find("ssl") or protocols_lower:find("tls")) then
      return
    end
    
    tls_packet_count = tls_packet_count + 1
    
    -- TLS version detection: Use multiple methods for accuracy
    local version_str = nil
    
    -- Method 0: Check supported_versions extension FIRST (MOST ACCURATE for TLS 1.3)
    -- This extension contains the actual negotiated version, not the legacy compatibility version
    -- Check this BEFORE anything else to avoid false matches
    if f_tls_supported_version then
      local supported_versions_field = f_tls_supported_version()
      if supported_versions_field then
        local max_version = 0
        
        -- Handle field extraction - Wireshark returns table for multiple occurrences
        if type(supported_versions_field) == "table" then
          -- Multiple occurrences - iterate through all
          for _, sv_field in ipairs(supported_versions_field) do
            local num_val = f2n(sv_field)
            if num_val and num_val > max_version then
              max_version = num_val
            end
          end
        else
          -- Single occurrence - get value directly
          local num_val = f2n(supported_versions_field)
          if num_val then
            max_version = num_val
          end
        end
        
        -- Map version numbers to version strings (check highest first - TLS 1.3 = 0x0304)
        if max_version == 0x0304 then
          version_str = "TLS 1.3"
        elseif max_version == 0x0303 then
          version_str = "TLS 1.2"
        elseif max_version == 0x0302 then
          version_str = "TLS 1.1"
        elseif max_version == 0x0301 then
          version_str = "TLS 1.0"
        elseif max_version == 0x0300 then
          version_str = "SSL 3.0"
        end
      end
    end
    
    -- Method 0b: Also check cipher suite IMMEDIATELY (reliable for TLS 1.3 in Server Hello)
    -- TLS 1.3 cipher suites are 0x1301-0x1305, and this is present in Server Hello
    -- Check this even if supported_versions didn't work, as it's very reliable
    if not version_str then
      local cipher = f2n(f_tls_handshake_ciphersuite)
      if cipher then
        -- TLS 1.3 cipher suites are in the range 0x1301-0x1305
        if cipher >= 0x1301 and cipher <= 0x1305 then
          version_str = "TLS 1.3"
        end
      end
    end
    
    
    -- Method 2: Check protocol string and pinfo protocol (less reliable, can be ambiguous)
    -- Wireshark shows "TLSv1.3 Record Layer" so check both frame.protocols and pinfo.cols.protocol
    -- Protocol string is colon-separated like "eth:ip:tcp:tlsv1.3" or "eth:ip:tcp:tls"
    -- IMPORTANT: Check TLS 1.3 patterns BEFORE TLS 1.2 to avoid false matches
    
    -- Combine protocol string and pinfo protocol for checking (use original case too)
    local all_protocols = protocols_lower
    local all_protocols_orig = tostring(protocols or "")
    if protocol_name and protocol_name ~= "" then
      all_protocols = all_protocols .. " " .. protocol_name:lower()
      all_protocols_orig = all_protocols_orig .. " " .. protocol_name
    end
    
    -- First check the protocol name column directly (most reliable - this is what Wireshark displays)
    local found_version = false
    
    -- Check protocol name column first (this shows "TLSv1.3" in Wireshark)
    if protocol_name and protocol_name ~= "" then
      local proto_lower = protocol_name:lower()
      if proto_lower:find("tlsv1%.3") or proto_lower:find("tlsv1:3") or
         proto_lower:find("tlsv1_3") or proto_lower:find("tlsv13") or
         protocol_name:find("TLSv1%.3") or protocol_name:find("TLSv1:3") or
         protocol_name:find("TLSv13") or protocol_name:find("TLSv1_3") then
        version_str = "TLS 1.3"
        found_version = true
      elseif proto_lower:find("tlsv1%.2") or proto_lower:find("tlsv1:2") or
             proto_lower:find("tlsv1_2") or proto_lower:find("tlsv12") or
             protocol_name:find("TLSv1%.2") or protocol_name:find("TLSv1:2") or
             protocol_name:find("TLSv12") or protocol_name:find("TLSv1_2") then
        version_str = "TLS 1.2"
        found_version = true
      elseif proto_lower:find("tlsv1%.1") or proto_lower:find("tlsv1:1") or
             protocol_name:find("TLSv1%.1") or protocol_name:find("TLSv1:1") then
        version_str = "TLS 1.1"
        found_version = true
      elseif proto_lower:find("tlsv1%.0") or proto_lower:find("tlsv1:0") or
             protocol_name:find("TLSv1%.0") or protocol_name:find("TLSv1:0") then
        version_str = "TLS 1.0"
        found_version = true
      end
    end
    
    -- If protocol name didn't help, check the full protocol string (case-insensitive and case-sensitive)
    if not found_version then
      -- Check for TLS 1.3 - try many variations
      if all_protocols:find("tlsv1%.3") or all_protocols:find("tlsv1:3") or
         all_protocols:find("tls%.1%.3") or all_protocols:find("tls 1%.3") or
         all_protocols:find("tlsv1_3") or all_protocols:find("tlsv13") or
         all_protocols:find("tls1%.3") or all_protocols:find("tls 1:3") or
         all_protocols:find("tls%-1%.3") or all_protocols:find("tlsv1%.3 record") or
         all_protocols:find("tlsv1%.3 layer") or
         all_protocols_orig:find("TLSv1%.3") or all_protocols_orig:find("TLSv1:3") or
         all_protocols_orig:find("TLS 1%.3") or all_protocols_orig:find("TLS%.1%.3") or
         all_protocols_orig:find("TLSv13") or all_protocols_orig:find("TLSv1_3") then
        version_str = "TLS 1.3"
        found_version = true
      end
    end
    
    -- Also check each protocol part individually (protocol string is colon-separated)
    if not found_version then
      for part in protocols_lower:gmatch("[^:]+") do
        if part:find("tlsv1%.3") or part:find("tlsv1:3") or part:find("tlsv1_3") or
           part:find("tlsv13") or part:find("tls1%.3") or part:find("tls%.1%.3") then
          version_str = "TLS 1.3"
          found_version = true
          break
        end
      end
    end
    
    -- Also check pinfo protocol directly
    if not found_version and pinfo_protocol ~= "" then
      if pinfo_protocol:find("tlsv1%.3") or pinfo_protocol:find("tlsv1:3") or
         pinfo_protocol:find("tlsv1_3") or pinfo_protocol:find("tlsv13") or
         pinfo_protocol:find("tls 1%.3") or pinfo_protocol:find("tls%.1%.3") then
        version_str = "TLS 1.3"
        found_version = true
      end
    end
    
    -- Now check for other TLS versions (only if TLS 1.3 not found)
    if not found_version then
      if all_protocols:find("tlsv1%.2") or all_protocols:find("tlsv1:2") or
         all_protocols:find("tls%.1%.2") or all_protocols:find("tls 1%.2") or
         all_protocols:find("tlsv1_2") or all_protocols:find("tlsv12") or
         all_protocols:find("tls1%.2") or all_protocols:find("tls 1:2") or
         all_protocols:find("tls%-1%.2") then
        version_str = "TLS 1.2"
        found_version = true
      else
        -- Check protocol parts for TLS 1.2
        for part in protocols_lower:gmatch("[^:]+") do
          if part:find("tlsv1%.2") or part:find("tlsv1:2") or part:find("tlsv1_2") or
             part:find("tlsv12") or part:find("tls1%.2") or part:find("tls%.1%.2") then
            version_str = "TLS 1.2"
            found_version = true
            break
          end
        end
      end
      
      -- Also check pinfo protocol for TLS 1.2
      if not found_version and pinfo_protocol ~= "" then
        if pinfo_protocol:find("tlsv1%.2") or pinfo_protocol:find("tlsv1:2") or
           pinfo_protocol:find("tlsv1_2") or pinfo_protocol:find("tlsv12") or
           pinfo_protocol:find("tls 1%.2") or pinfo_protocol:find("tls%.1%.2") then
          version_str = "TLS 1.2"
          found_version = true
        end
      end
    end
    
    if not found_version then
      if all_protocols:find("tlsv1%.1") or all_protocols:find("tlsv1:1") or
         all_protocols:find("tls%.1%.1") or all_protocols:find("tls 1%.1") or
         all_protocols:find("tlsv1_1") or all_protocols:find("tlsv11") then
        version_str = "TLS 1.1"
        found_version = true
      end
    end
    
    if not found_version then
      if all_protocols:find("tlsv1%.0") or all_protocols:find("tlsv1:0") or
         all_protocols:find("tls%.1%.0") or all_protocols:find("tls 1%.0") or
         all_protocols:find("tlsv1_0") or all_protocols:find("tlsv10") then
        version_str = "TLS 1.0"
        found_version = true
      end
    end
    
    if not found_version then
      if all_protocols:find("ssl%.3%.0") or all_protocols:find("sslv3") or
         all_protocols:find("ssl%.3") or all_protocols:find("ssl 3") then
        version_str = "SSL 3.0"
      end
    end
    
    -- Method 3: Fall back to handshake.version field ONLY (for handshake packets)
    -- Note: We skip record.version entirely because it's misleading (TLS 1.3 uses 0x0303 for compatibility)
    -- Only use handshake.version if we're in a handshake packet and haven't detected via other methods
    if not version_str then
      local handshake_version = f2n(f_tls_handshake_version)
      
      -- Only use handshake version if present (indicates we're in a handshake packet)
      if handshake_version then
        if handshake_version == 0x0304 then
          version_str = "TLS 1.3"  -- Handshake version 0x0304 indicates TLS 1.3
        elseif handshake_version == 0x0301 then
          version_str = "TLS 1.0"
        elseif handshake_version == 0x0302 then
          version_str = "TLS 1.1"
        elseif handshake_version == 0x0303 then
          -- Handshake version 0x0303 is TLS 1.2 (not ambiguous like record.version)
          version_str = "TLS 1.2"
        elseif handshake_version == 0x0300 then
          version_str = "SSL 3.0"
        end
      end
      -- NOTE: We intentionally skip record.version because it's misleading:
      -- TLS 1.3 uses 0x0303 in record layer for compatibility, so we can't reliably
      -- distinguish TLS 1.2 from TLS 1.3 using record.version alone.
      -- We only count versions from handshake packets (supported_versions, cipher suite, or handshake.version)
    end
    
    -- Only record known TLS/SSL versions
    -- IMPORTANT: For TLS 1.3, we should only count when we have reliable detection
    -- (supported_versions extension or TLS 1.3 cipher suite)
    -- If we couldn't determine reliably, don't guess - skip this packet's version count
    if version_str then
      stats.versions[version_str] = (stats.versions[version_str] or 0) + 1
    else
      -- Couldn't determine version - this is OK for non-handshake packets
      -- Don't count them as any version to avoid false positives
    end
    
    -- SNI (Server Name Indication)
    local sni = f2s(f_tls_handshake_sni)
    if sni then
      stats.sni_names[sni] = (stats.sni_names[sni] or 0) + 1
      stats.total_connections = stats.total_connections + 1
    end
    
    -- Cipher suites
    local cipher = f2n(f_tls_handshake_ciphersuite)
    if cipher then
      local cipher_str = string.format("0x%04x", cipher)
      stats.cipher_suites[cipher_str] = (stats.cipher_suites[cipher_str] or 0) + 1
    end
    
    -- Certificate common names
    local cert_cn = f2s(f_tls_cert_subject_cn) or f2s(f_tls_cert_common_name)
    if cert_cn then
      stats.cert_common_names[cert_cn] = (stats.cert_common_names[cert_cn] or 0) + 1
    end
  end
  
  retap_packets()
  tap:remove()
  
  -- Debug info
  stats.debug_packet_count = packet_count
  stats.debug_tls_packet_count = tls_packet_count
  
  return stats
end

------------------------------------------------------------
-- Context would go here if dialog worked properly
------------------------------------------------------------

------------------------------------------------------------
-- Report Generators
------------------------------------------------------------

------------------------------------------------------------
-- Summary Report
------------------------------------------------------------
local function generate_summary_report_internal()
  local tw = TextWindow.new("PacketReporter - Summary")
  tw:clear()
  tw:append("Generating Summary Report...\n")
  
  -- Collect data
  local basic_stats = collect_basic_stats()
  
  if basic_stats.total_packets == 0 then
    tw:append("No packets found in current capture.\n")
    return
  end
  
  tw:append(string.format("Collected stats: %d packets, %s\n", 
    basic_stats.total_packets, format_bytes(basic_stats.total_bytes)))
  
  
  -- Convert data to chart format
  local top_ips = {}
  for ip, count in pairs(basic_stats.ip_addresses) do
    table.insert(top_ips, {label = ip, value = count})
  end
  table.sort(top_ips, function(a, b) return a.value > b.value end)
  local top_10_ips = {}
  for i = 1, math.min(10, #top_ips) do
    table.insert(top_10_ips, top_ips[i])
  end
  
  local proto_data = {}
  for proto, count in pairs(basic_stats.protocols) do
    table.insert(proto_data, {label = proto, value = count})
  end
  table.sort(proto_data, function(a, b) return a.value > b.value end)
  local top_protos = {}
  for i = 1, math.min(10, #proto_data) do
    table.insert(top_protos, proto_data[i])
  end
  
  local tcp_port_data = {}
  for port, count in pairs(basic_stats.tcp_ports) do
    table.insert(tcp_port_data, {label = tostring(port), value = count})
  end
  table.sort(tcp_port_data, function(a, b) return a.value > b.value end)
  local top_tcp = {}
  for i = 1, math.min(5, #tcp_port_data) do
    table.insert(top_tcp, tcp_port_data[i])
  end
  
  -- Generate SVG
  local paper = current_paper_size
  local out = {}
  local function add(s) table.insert(out, s) end
  
  add('<?xml version="1.0" encoding="UTF-8"?>\n')
  add('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n')
  add('<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="'..paper.width..'" height="'..paper.height..'" viewBox="0 0 '..paper.width..' '..paper.height..'">\n')
  add('<rect x="0" y="0" width="100%" height="100%" fill="white"/>\n')
  
  -- Title
  add('<text x="'..(paper.width/2)..'" y="40" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="24" font-weight="700" fill="#111">PacketReporter - Summary Network Analysis Report</text>\n')
  add('<text x="'..(paper.width/2)..'" y="65" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">Generated: '..os.date("%Y-%m-%d %H:%M:%S")..'</text>\n')
  
  -- Summary box
  local box_y = 90
  add(string.format('<rect x="50" y="%d" width="%d" height="120" fill="#f0f9ff" stroke="#2C7BB6" stroke-width="2" rx="5"/>\n', box_y, paper.width - 100))
  add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="16" font-weight="700" fill="#111">Overview Statistics</text>\n', box_y + 25))
  
  local duration = 0
  if basic_stats.start_time and basic_stats.end_time then
    duration = basic_stats.end_time - basic_stats.start_time
  end
  
  add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#333">Total Packets: <tspan font-weight="700">%d</tspan></text>\n', 
    box_y + 50, basic_stats.total_packets))
  add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#333">Total Bytes: <tspan font-weight="700">%s</tspan></text>\n', 
    box_y + 70, format_bytes(basic_stats.total_bytes)))
  add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#333">Duration: <tspan font-weight="700">%.2f seconds</tspan></text>\n', 
    box_y + 90, duration))
  add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#333">Unique IPs: <tspan font-weight="700">%d</tspan></text>\n', 
    paper.width/2 + 50, box_y + 50, #top_ips))
  add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#333">Protocols: <tspan font-weight="700">%d</tspan></text>\n', 
    paper.width/2 + 50, box_y + 70, #proto_data))
  
  -- Charts
  local chart_y = 240
  
  -- Top IPs bar chart
  if #top_10_ips > 0 then
    add(generate_bar_chart(top_10_ips, "Top 10 IP Addresses", 50, chart_y, paper.width - 100, 250, true))
    chart_y = chart_y + 280
  end
  
  -- Protocol distribution pie chart
  if #top_protos > 0 then
    add(generate_pie_chart(top_protos, "Protocol Distribution", paper.width/2, chart_y + 120, 100, true))
    chart_y = chart_y + 280
  end
  
  -- Top TCP ports bar chart
  if #top_tcp > 0 then
    add(generate_bar_chart(top_tcp, "Top 5 TCP Ports", 50, chart_y, paper.width - 100, 200, true))
  end
  
  add('</svg>\n')
  
  local svg = table.concat(out)
  local svg_path = tmp_svg()
  local fh, err = io.open(svg_path, "wb")
  if not fh then
    tw:append("Failed to write SVG: "..tostring(err).."\n")
    return
  end
  fh:write(svg)
  fh:close()
  
  tw:append("SVG generated: "..svg_path.."\n")
  
  local tools = detect_converters()
  -- Only report if all dependencies are met, otherwise show what's missing
  local has_converter = tools.rsvg or tools.inkscape or tools.magick
  if has_converter then
    tw:append("\n✓ All dependencies met - PDF export available\n")
  else
    tw:append("\n✗ Missing dependencies:\n")
    tw:append("  - SVG converter: rsvg-convert, inkscape, or imagemagick\n")
    tw:append("  Install: brew install librsvg (recommended)\n")
  end
  
  tw:add_button("Export PDF", function()
    export_single_page_pdf(svg_path, tw, tools, paper.name)
  end)
  
  tw:add_button("Open SVG", function()
    if not try_open_in_browser(svg_path) then
      tw:append("Could not auto-open; open the file manually.\n")
    end
  end)
end

------------------------------------------------------------
-- Detailed Report (Phase 1 Enhanced)
------------------------------------------------------------
local function generate_detailed_report_internal()
  local tw = TextWindow.new("PacketReporter - Detailed Report")
  tw:clear()
  tw:append("Generating Detailed Report...\n")
  
  -- Collect all statistics
  local basic_stats = collect_basic_stats()
  local dns_stats = collect_dns_stats()
  local http_stats = collect_http_stats()
  local mac_stats = collect_mac_stats()
  local ip_stats = collect_ip_stats()
  local tcp_stats = collect_tcp_stats()
  local tls_stats = collect_tls_stats()
  
  if basic_stats.total_packets == 0 then
    tw:append("No packets found in current capture.\n")
    return
  end
  
  tw:append(string.format("Analyzed %d packets\n", basic_stats.total_packets))
  
  local tls_version_count = 0
  for k,v in pairs(tls_stats.versions) do 
    tls_version_count = tls_version_count + 1
    tw:append(string.format("  TLS version %s: %d\n", k, v))
  end
  local tls_sni_count = 0
  for k,v in pairs(tls_stats.sni_names) do 
    tls_sni_count = tls_sni_count + 1
  end
  local quic_info = ""
  if tls_stats.quic_count and tls_stats.quic_count > 0 then
    quic_info = string.format(", QUIC packets: %d", tls_stats.quic_count)
  end
  tw:append(string.format("TLS versions found: %d, SNI names: %d%s\n", tls_version_count, tls_sni_count, quic_info))
  
  -- Helper to convert dict to sorted array
  local function dict_to_sorted_array(dict, limit)
    local arr = {}
    for key, count in pairs(dict) do
      table.insert(arr, {label = key, value = count})
    end
    table.sort(arr, function(a, b) return a.value > b.value end)
    local result = {}
    for i = 1, math.min(limit or #arr, #arr) do
      table.insert(result, arr[i])
    end
    return result
  end
  
  -- Prepare data
  local top_10_ips = dict_to_sorted_array(basic_stats.ip_addresses, 10)
  local top_protocols = dict_to_sorted_array(basic_stats.protocols, 10)
  local top_5_tcp = dict_to_sorted_array(basic_stats.tcp_ports, 5)
  local top_5_udp = dict_to_sorted_array(basic_stats.udp_ports, 5)
  local top_10_dns_queries = dict_to_sorted_array(dns_stats.queries, 10)
  local top_10_dns_ips = dict_to_sorted_array(dns_stats.ips, 10)
  local top_10_http_ua = dict_to_sorted_array(http_stats.user_agents, 10)
  local top_10_http_hosts = dict_to_sorted_array(http_stats.hosts, 10)
  local top_5_http_codes = dict_to_sorted_array(http_stats.status_codes, 5)
  
  -- Get PCAP file info if available
  local pcap_file = ""
  local pcap_size = ""
  if CaptureInfo then
    if CaptureInfo.file then
      pcap_file = tostring(CaptureInfo.file)
      -- Extract just filename
      pcap_file = pcap_file:match("([^/\\]+)$") or pcap_file
    end
    if CaptureInfo.filesize then
      pcap_size = format_bytes(tonumber(CaptureInfo.filesize))
    end
  end
  
  -- Generate SVG
  local paper = current_paper_size
  local out = {}
  local function add(s) table.insert(out, s) end
  
  add('<?xml version="1.0" encoding="UTF-8"?>\n')
  add('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">\n')
  add('<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="'..paper.width..'" height="'..math.max(paper.height, 3000)..'" viewBox="0 0 '..paper.width..' '..math.max(paper.height, 3000)..'">\n')
  add('<rect x="0" y="0" width="100%" height="100%" fill="white"/>\n')
  
  -- Title
  add('<text x="'..(paper.width/2)..'" y="80" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="24" font-weight="700" fill="#111">PacketReporter - Detailed Network Analysis Report</text>\n')
  add('<text x="'..(paper.width/2)..'" y="105" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">Generated: '..os.date("%Y-%m-%d %H:%M:%S")..'</text>\n')
  
  local y_pos = 205  -- Increased from 130 to add ~2cm space before Section 1
  
  -- Section 1: Summary with PCAP info
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">1. Summary</text>\n', y_pos))
  y_pos = y_pos + 30
  
  -- PCAP File Information
  if pcap_file ~= "" then
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="13" font-weight="700" fill="#111">PCAP File Information</text>\n', y_pos))
    y_pos = y_pos + 20
    add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">File: <tspan fill="#333" font-weight="600">%s</tspan></text>\n', y_pos, xml_escape(pcap_file)))
    y_pos = y_pos + 18
    if pcap_size ~= "" then
      add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Size: <tspan fill="#333" font-weight="600">%s</tspan></text>\n', y_pos, pcap_size))
      y_pos = y_pos + 18
    end
    if basic_stats.start_time then
      local start_str = os.date("%Y-%m-%d %H:%M:%S", math.floor(basic_stats.start_time))
      add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">First Packet: <tspan fill="#333" font-weight="600">%s</tspan></text>\n', y_pos, start_str))
      y_pos = y_pos + 18
    end
    if basic_stats.end_time then
      local end_str = os.date("%Y-%m-%d %H:%M:%S", math.floor(basic_stats.end_time))
      add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Last Packet: <tspan fill="#333" font-weight="600">%s</tspan></text>\n', y_pos, end_str))
      y_pos = y_pos + 18
    end
    y_pos = y_pos + 10
  end
  
  -- Statistics
  add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="13" font-weight="700" fill="#111">Capture Statistics</text>\n', y_pos))
  y_pos = y_pos + 20
  add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Total Packets: <tspan fill="#333" font-weight="700">%d</tspan></text>\n', y_pos, basic_stats.total_packets))
  y_pos = y_pos + 18
  add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Total Bytes: <tspan fill="#333" font-weight="700">%s</tspan></text>\n', y_pos, format_bytes(basic_stats.total_bytes)))
  y_pos = y_pos + 18
  local duration = 0
  if basic_stats.start_time and basic_stats.end_time then
    duration = basic_stats.end_time - basic_stats.start_time
  end
  add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Duration: <tspan fill="#333" font-weight="700">%.2f seconds</tspan></text>\n', y_pos, duration))
  y_pos = y_pos + 18
  add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Unique IP Addresses: <tspan fill="#333" font-weight="700">%d</tspan></text>\n', y_pos, #top_10_ips))
  y_pos = y_pos + 50  -- Balanced spacing between sections
  
  -- Helper function to pad table data to consistent size
  local function pad_table_data(data, max_rows)
    local padded = {}
    for i, item in ipairs(data) do
      table.insert(padded, item)
    end
    -- Pad with n/a entries if fewer than max_rows
    for i = #data + 1, max_rows do
      local na_row = {rank = i}
      -- Add n/a for all other fields
      for k, v in pairs(data[1] or {}) do
        if k ~= "rank" then
          na_row[k] = "n/a"
        end
      end
      table.insert(padded, na_row)
    end
    return padded
  end
  
  -- Helper function for Legal: force page break if needed for large sections
  local function force_page_break_if_needed_legal(min_space_needed)
    if paper.name ~= "Legal" then
      return  -- Only apply to Legal paper
    end
    
    local bottom_margin = 60
    local current_page_num = math.floor(y_pos / paper.height)
    local y_on_page = y_pos - (current_page_num * paper.height)
    local space_left = (paper.height - bottom_margin) - y_on_page
    
    if space_left < min_space_needed then
      -- Not enough space, move to next page
      local padding = paper.height - y_on_page
      add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
      y_pos = y_pos + padding + 80
    end
  end
  
  -- Helper function for page boundary checks
  local function check_page_boundary(required_space)
    local bottom_margin = 60
    local current_page_num = math.floor(y_pos / paper.height)
    
    -- For A4: Skip page boundary checks on page 1 (page 0) to allow all content to fit naturally
    -- For Legal: Apply boundary checks on all pages to prevent section splits
    if current_page_num == 0 and paper.name == "A4" then
      return
    end
    
    -- Calculate how much space is left on current page
    local y_on_current_page = y_pos - (current_page_num * paper.height)
    local page_bottom = paper.height - bottom_margin
    local space_remaining = page_bottom - y_on_current_page
    
    -- If not enough space for the required content, move to next page
    if space_remaining < required_space then
      local padding = paper.height - y_on_current_page
      add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
      y_pos = y_pos + padding + 80  -- 80px top margin on new page
    end
  end
  
  -- Section 2: Top 10 IP Addresses (Bar Chart)
  force_page_break_if_needed_legal(400)  -- Legal: ensure section fits
  check_page_boundary(330)  -- Section title + chart
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">2. Top 10 IP Addresses</text>\n', y_pos))
  y_pos = y_pos + 30
  if #top_10_ips > 0 then
    add(generate_bar_chart(top_10_ips, "", 50, y_pos, paper.width - 100, 250, false))
    y_pos = y_pos + 330  -- Balanced spacing (280px chart + 50px gap)
  else
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No IP traffic detected</text>\n', y_pos))
    y_pos = y_pos + 30
  end
  
  -- Section 3: Top Protocols and Applications (Pie Chart)
  force_page_break_if_needed_legal(400)  -- Legal: ensure section fits
  check_page_boundary(350)  -- Section title + pie chart
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">3. Top Protocols and Applications</text>\n', y_pos))
  y_pos = y_pos + 30
  if #top_protocols > 0 then
    add(generate_pie_chart(top_protocols, "", paper.width/2, y_pos + 130, 110, true))
    y_pos = y_pos + 300
  else
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No protocol data</text>\n', y_pos))
    y_pos = y_pos + 30
  end
  
  -- Section 4: Communication Matrix (Circle Visualization)
  force_page_break_if_needed_legal(700)  -- Legal: ensure entire visualization fits (conservative)
  -- For A4 paper: force page break if still on page 1 to ensure clean start on page 2
  if paper.name == "A4" and y_pos < paper.height then
    local padding = paper.height - y_pos
    add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
    y_pos = y_pos + padding + 80
  end
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">4. IP Communication Matrix (Top 10 Hosts)</text>\n', y_pos))
  y_pos = y_pos + 78  -- Increased spacing (40 + 38px ≈ 1cm)
  
  -- Build directional circle visualization of IP communications
  if #top_10_ips > 0 then
    local cx = paper.width / 2
    local cy = y_pos + 220  -- Space for top labels
    local radius = 160  -- Circle radius
    local label_radius = radius + 32  -- Label distance
    
    -- Build IP communication matrix from basic_stats
    local ip_matrix = {}
    local ip_to_idx = {}
    for i, item in ipairs(top_10_ips) do
      ip_to_idx[item.label] = i
      ip_matrix[i] = {}
    end
    
    -- Collect directional flows (need to retap to get src->dst pairs)
    local tap = Listener.new("frame", nil)
    function tap.packet(pinfo, tvb)
      local src = f2s(f_ip_src) or f2s(f_ip6_src)
      local dst = f2s(f_ip_dst) or f2s(f_ip6_dst)
      if src and dst then
        local si = ip_to_idx[src]
        local di = ip_to_idx[dst]
        if si and di and si ~= di then
          ip_matrix[si][di] = (ip_matrix[si][di] or 0) + 1
        end
      end
    end
    retap_packets()
    tap:remove()
    
    -- Calculate node positions around circle
    local positions = {}
    local num_nodes = math.min(#top_10_ips, 10)  -- Limit to 10 for clarity
    for i = 1, num_nodes do
      local angle = (2 * math.pi) * (i - 1) / num_nodes - math.pi / 2
      positions[i] = {
        x = cx + radius * math.cos(angle),
        y = cy + radius * math.sin(angle),
        angle = angle
      }
    end
    
    -- Traffic classification bins
    local bins = {
      {min=1,    max=10,    width=1.5,  color="#2C7BB6"},
      {min=11,   max=100,   width=3.0,  color="#00A6CA"},
      {min=101,  max=500,   width=5.0,  color="#00CCBC"},
      {min=501,  max=1000,  width=7.0,  color="#FF8C42"},
      {min=1001, max=nil,   width=10.0, color="#FF6B6B"}
    }
    
    local function classify(count)
      for _, b in ipairs(bins) do
        if count >= b.min and (not b.max or count <= b.max) then
          return b
        end
      end
      return bins[1]
    end
    
    -- Draw directional communication links
    for si = 1, num_nodes do
      local p1 = positions[si]
      for di = 1, num_nodes do
        if si ~= di and ip_matrix[si] and ip_matrix[si][di] and ip_matrix[si][di] > 0 then
          local p2 = positions[di]
          local count = ip_matrix[si][di]
          local bin = classify(count)
          
          -- Draw curved path through center
          local path = string.format('M %.2f %.2f Q %.2f %.2f %.2f %.2f', 
            p1.x, p1.y, cx, cy, p2.x, p2.y)
          add(string.format('<path d="%s" fill="none" stroke="%s" stroke-opacity="0.5" stroke-width="%.1f"/>\n',
            path, bin.color, bin.width))
        end
      end
    end
    
    -- Draw nodes
    for i = 1, num_nodes do
      local p = positions[i]
      add(string.format('<circle cx="%.2f" cy="%.2f" r="5.5" fill="#000000"/>\n', p.x, p.y))
    end
    
    -- Draw labels
    for i = 1, num_nodes do
      local p = positions[i]
      local ip = top_10_ips[i].label
      local angle_deg = p.angle * 180 / math.pi
      local flip = (angle_deg > 90 or angle_deg < -90)
      local rot = angle_deg + (flip and 180 or 0)
      local lx = cx + label_radius * math.cos(p.angle)
      local ly = cy + label_radius * math.sin(p.angle)
      local anchor = flip and "end" or "start"
      local dx = flip and -8 or 8
      
      -- Label outline (white stroke)
      add(string.format('<text x="%.2f" y="%.2f" transform="rotate(%.1f %.2f %.2f)" text-anchor="%s" font-family="Arial, Helvetica, sans-serif" font-size="10" stroke="white" stroke-width="2.5" stroke-linejoin="round" fill="none"><tspan dx="%d">%s</tspan></text>\n',
        lx, ly, rot, lx, ly, anchor, dx, xml_escape(ip)))
      -- Label fill
      add(string.format('<text x="%.2f" y="%.2f" transform="rotate(%.1f %.2f %.2f)" text-anchor="%s" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="#000000"><tspan dx="%d">%s</tspan></text>\n',
        lx, ly, rot, lx, ly, anchor, dx, xml_escape(ip)))
    end
    
    -- Center label
    add(string.format('<rect x="%d" y="%d" width="140" height="32" fill="white" fill-opacity="0.95"/>\n', cx - 70, cy - 16))
    add(string.format('<text x="%d" y="%d" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#111">IP Communications</text>\n', cx, cy + 5))
    
    -- Legend (more compact)
    local legend_x = 60
    local legend_y = cy + radius + 30  -- Reduced spacing
    add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="#444">Traffic Volume (packets):</text>\n', legend_x, legend_y))
    for i, bin in ipairs(bins) do
      local ly = legend_y + 5 + (i * 18)  -- Reduced spacing between legend items
      local label = bin.max and string.format("%d-%d", bin.min, bin.max) or string.format("%d+", bin.min)
      add(string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" stroke="%s" stroke-opacity="0.75" stroke-width="%.1f"/>\n',
        legend_x, ly, legend_x + 70, ly, bin.color, bin.width))  -- Shorter lines
      add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="9" fill="#333">%s packets</text>\n',
        legend_x + 78, ly + 3, label))  -- Smaller font
    end
    
    y_pos = legend_y + 170  -- Reduced spacing to match section 2-3 spacing (50px)
  else
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No IP traffic for matrix visualization</text>\n', y_pos))
    y_pos = y_pos + 30
  end
  
  -- Section 5: Port Analysis
  force_page_break_if_needed_legal(350)  -- Legal: ensure section fits
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">5. Port Analysis</text>\n', y_pos))
  y_pos = y_pos + 30
  add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">5.1 Top 5 TCP Ports</text>\n', y_pos))
  y_pos = y_pos + 30
  if #top_5_tcp > 0 then
    add(generate_bar_chart(top_5_tcp, "", 50, y_pos, (paper.width - 150) / 2, 200, false))
  else
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No TCP traffic</text>\n', y_pos))
  end
  
  -- Top 5 UDP Ports (side by side)
  local udp_x = 50 + (paper.width - 150) / 2 + 50
  add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">5.2 Top 5 UDP Ports</text>\n', udp_x, y_pos - 30))
  if #top_5_udp > 0 then
    add(generate_bar_chart(top_5_udp, "", udp_x, y_pos, (paper.width - 150) / 2, 200, false))
  else
    add(string.format('<text x="%d" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No UDP traffic</text>\n', udp_x + 20, y_pos))
  end
  y_pos = y_pos + 240
  
  -- Section 6: DNS Analysis (Table View) - Force to new page
  local bottom_margin = 60
  local page_usable_height = paper.height - bottom_margin
  local current_page_num = math.floor(y_pos / paper.height)
  local space_on_page = page_usable_height - (y_pos - (current_page_num * paper.height))
  
  -- Always move to next page for DNS Analysis
  local padding = paper.height - (y_pos - (current_page_num * paper.height))
  add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
  y_pos = y_pos + padding + 80
  
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">6. DNS Analysis</text>\n', y_pos))
  y_pos = y_pos + 30
  
  if #top_10_dns_queries > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">6.1 Top 10 DNS Queries</text>\n', y_pos))
    y_pos = y_pos + 20
    
    -- Prepare DNS table data and pad to 10 rows
    local dns_table_data = {}
    for i, item in ipairs(top_10_dns_queries) do
      table.insert(dns_table_data, {rank = i, domain = item.label, count = item.value})
    end
    dns_table_data = pad_table_data(dns_table_data, 10)  -- Pad to 10 rows
    
    local dns_cols = {
      {title = "#", field = "rank"},
      {title = "Domain", field = "domain"},
      {title = "Queries", field = "count"}
    }
    
    local dns_svg, dns_height = generate_table(dns_table_data, "", 60, y_pos, paper.width - 120, dns_cols)
    
    -- Check if table would exceed bottom margin
    local bottom_margin = 60
    local page_usable_height = paper.height - bottom_margin
    local current_page_num = math.floor(y_pos / paper.height)
    local space_on_page = page_usable_height - (y_pos - (current_page_num * paper.height))
    
    if dns_height > space_on_page then
      -- Table won't fit, move to next page
      local padding = paper.height - (y_pos - (current_page_num * paper.height))
      add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
      y_pos = y_pos + padding + 80
      -- Regenerate table at new position
      dns_svg, dns_height = generate_table(dns_table_data, "", 60, y_pos, paper.width - 120, dns_cols)
    end
    
    add(dns_svg)
    y_pos = y_pos + dns_height + 30
  else
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No DNS queries detected</text>\n', y_pos))
    y_pos = y_pos + 30
  end
  
  -- 6.2 DNS Record Types
  local top_record_types = dict_to_sorted_array(dns_stats.record_types, 10)
  if #top_record_types > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">6.2 DNS Record Types Distribution</text>\n', y_pos))
    y_pos = y_pos + 25
    
    -- Pie chart for record types
    add(generate_pie_chart(top_record_types, "", paper.width/2, y_pos + 100, 90, true))
    y_pos = y_pos + 240
  end
  
  -- 6.3 Authoritative vs Non-Authoritative Responses
  if dns_stats.total_responses > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">6.3 DNS Response Analysis</text>\n', y_pos))
    y_pos = y_pos + 25
    
    local response_data = {
      {label = "Authoritative", value = dns_stats.authoritative},
      {label = "Non-Authoritative", value = dns_stats.non_authoritative}
    }
    add(generate_pie_chart(response_data, "", paper.width/2, y_pos + 100, 90, true))
    y_pos = y_pos + 240
    
    -- Summary stats
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Total Queries: <tspan fill="#333" font-weight="600">%d</tspan>  |  Total Responses: <tspan fill="#333" font-weight="600">%d</tspan></text>\n', 
      y_pos, dns_stats.total_queries, dns_stats.total_responses))
    y_pos = y_pos + 40
  end
  
  -- Section 7: TLS/SSL Analysis - Force to new page
  local top_tls_versions = dict_to_sorted_array(tls_stats.versions, 10)
  local top_sni_names = dict_to_sorted_array(tls_stats.sni_names, 10)
  local top_cert_names = dict_to_sorted_array(tls_stats.cert_common_names, 10)
  
  if #top_tls_versions > 0 or #top_sni_names > 0 then
    -- Force page break
    local bottom_margin = 60
    local page_usable_height = paper.height - bottom_margin
    local current_page_num = math.floor(y_pos / paper.height)
    local padding = paper.height - (y_pos - (current_page_num * paper.height))
    add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
    y_pos = y_pos + padding + 80
    
    add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">7. TLS/SSL Analysis</text>\n', y_pos))
    y_pos = y_pos + 30
    
    -- TLS Version distribution (horizontal bar chart)
    if #top_tls_versions > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">7.1 TLS/SSL/QUIC Version Distribution</text>\n', y_pos))
      y_pos = y_pos + 20
      
      -- Add subtitle indicating what the numbers represent (make it very visible)
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#444" font-weight="500">Values represent the number of observed handshakes</text>\n', y_pos))
      y_pos = y_pos + 30
      
      local bar_height = 30
      local bar_x_start = 150
      local max_bar_width = paper.width - 250
      
      -- Find max value for scaling
      local max_val = 0
      for _, item in ipairs(top_tls_versions) do
        if item.value > max_val then max_val = item.value end
      end
      if max_val == 0 then max_val = 1 end
      
      -- Draw horizontal bars
      local colors = {"#2C7BB6", "#00A6CA", "#00CCBC", "#90EE90", "#FFD700", "#FF8C42"}
      for i, item in ipairs(top_tls_versions) do
        local bar_y = y_pos + (i - 1) * (bar_height + 8)
        local bar_width = (item.value / max_val) * max_bar_width
        local color = colors[((i - 1) % #colors) + 1]
        
        -- Version label (left)
        add(string.format('<text x="135" y="%d" text-anchor="end" font-family="Arial, Helvetica, sans-serif" font-size="11" font-weight="600" fill="#333">%s</text>\n',
          bar_y + bar_height/2 + 4, xml_escape(tostring(item.label))))
        
        -- Bar
        add(string.format('<rect x="%d" y="%d" width="%.1f" height="%d" fill="%s" fill-opacity="0.8"/>\n',
          bar_x_start, bar_y, bar_width, bar_height, color))
        
        -- Value label at the end of the bar (right edge, not going beyond) with white text
        local label_x = bar_x_start + bar_width - 8  -- 8px padding from right edge
        local label_fill = "#ffffff"  -- Always white (inverted) for visibility on colored bar
        local label_text = tostring(item.value)
        
        -- Ensure label doesn't go beyond bar (use text-anchor="end" for right alignment)
        add(string.format('<text x="%.1f" y="%d" text-anchor="end" font-family="Arial, Helvetica, sans-serif" font-size="10" font-weight="600" fill="%s">%s</text>\n',
          label_x, bar_y + bar_height/2 + 4, label_fill, label_text))
      end
      
      y_pos = y_pos + (#top_tls_versions * (bar_height + 8)) + 30
    end
    
    -- Top SNI names
    if #top_sni_names > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">7.2 Top 10 TLS Server Names (SNI)</text>\n', y_pos))
      y_pos = y_pos + 20
      
      local sni_table_data = {}
      for i, item in ipairs(top_sni_names) do
        table.insert(sni_table_data, {rank = i, server_name = item.label, count = item.value})
      end
      sni_table_data = pad_table_data(sni_table_data, 10)
      
      local sni_cols = {
        {title = "#", field = "rank"},
        {title = "Server Name", field = "server_name"},
        {title = "Connections", field = "count"}
      }
      
      local sni_svg, sni_height = generate_table(sni_table_data, "", 60, y_pos, paper.width - 120, sni_cols)
      add(sni_svg)
      y_pos = y_pos + sni_height + 30
    end
    
    -- Top certificate names (if available)
    if #top_cert_names > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">7.3 Top 10 Certificate Common Names</text>\n', y_pos))
      y_pos = y_pos + 20
      
      local cert_table_data = {}
      for i, item in ipairs(top_cert_names) do
        table.insert(cert_table_data, {rank = i, cert_name = item.label, count = item.value})
      end
      cert_table_data = pad_table_data(cert_table_data, 10)
      
      local cert_cols = {
        {title = "#", field = "rank"},
        {title = "Common Name", field = "cert_name"},
        {title = "Count", field = "count"}
      }
      
      local cert_svg, cert_height = generate_table(cert_table_data, "", 60, y_pos, paper.width - 120, cert_cols)
      add(cert_svg)
      y_pos = y_pos + cert_height + 30
    end
    
    -- Summary stats
    if tls_stats.total_connections > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Total TLS Connections: <tspan fill="#333" font-weight="600">%d</tspan></text>\n', 
        y_pos, tls_stats.total_connections))
      y_pos = y_pos + 30
    end
  end
  
  -- Section 8: HTTP Analysis - Force to new page
  local bottom_margin = 60
  local page_usable_height = paper.height - bottom_margin
  local current_page_num = math.floor(y_pos / paper.height)
  local padding = paper.height - (y_pos - (current_page_num * paper.height))
  add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
  y_pos = y_pos + padding + 80
  
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">8. HTTP Analysis</text>\n', y_pos))
  y_pos = y_pos + 30
  
  if #top_10_http_ua > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">8.1 Top 10 HTTP User-Agents</text>\n', y_pos))
    y_pos = y_pos + 20
    
    -- Prepare User-Agent table data and pad to 10 rows
    local ua_table_data = {}
    for i, item in ipairs(top_10_http_ua) do
      table.insert(ua_table_data, {rank = i, user_agent = item.label, count = item.value})
    end
    ua_table_data = pad_table_data(ua_table_data, 10)  -- Pad to 10 rows
    
    local ua_cols = {
      {title = "#", field = "rank"},
      {title = "User-Agent", field = "user_agent"},
      {title = "Requests", field = "count"}
    }
    
    local ua_svg, ua_height = generate_table(ua_table_data, "", 60, y_pos, paper.width - 120, ua_cols)
    add(ua_svg)
    y_pos = y_pos + ua_height + 20
  else
    add(string.format('<text x="70" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="12" fill="#666">No HTTP traffic detected</text>\n', y_pos))
    y_pos = y_pos + 30
  end
  
  if #top_10_http_hosts > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">8.2 Top 10 HTTP Hosts</text>\n', y_pos))
    y_pos = y_pos + 20
    
    -- Prepare Hosts table data and pad to 10 rows
    local hosts_table_data = {}
    for i, item in ipairs(top_10_http_hosts) do
      table.insert(hosts_table_data, {rank = i, host = item.label, count = item.value})
    end
    hosts_table_data = pad_table_data(hosts_table_data, 10)  -- Pad to 10 rows
    
    local hosts_cols = {
      {title = "#", field = "rank"},
      {title = "Host", field = "host"},
      {title = "Requests", field = "count"}
    }
    
    local hosts_svg, hosts_height = generate_table(hosts_table_data, "", 60, y_pos, paper.width - 120, hosts_cols)
    add(hosts_svg)
    y_pos = y_pos + hosts_height + 20
  end
  
  if #top_5_http_codes > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">8.3 HTTP Status Codes</text>\n', y_pos))
    y_pos = y_pos + 20
    
    -- Generate horizontal bar chart for status codes
    local bar_height = 30
    local bar_x_start = 150
    local max_bar_width = paper.width - 250
    
    -- Find max value for scaling
    local max_val = 0
    for _, item in ipairs(top_5_http_codes) do
      if item.value > max_val then max_val = item.value end
    end
    if max_val == 0 then max_val = 1 end
    
    -- Draw horizontal bars
    local colors = {"#2C7BB6", "#00A6CA", "#00CCBC", "#90EE90", "#FFD700"}
    for i, item in ipairs(top_5_http_codes) do
      local bar_y = y_pos + (i - 1) * (bar_height + 8)
      local bar_width = (item.value / max_val) * max_bar_width
      local color = colors[((i - 1) % #colors) + 1]
      
      -- Status code label (left)
      add(string.format('<text x="80" y="%d" text-anchor="end" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#333">%s</text>\n',
        bar_y + bar_height/2 + 4, xml_escape(tostring(item.label))))
      
      -- Bar
      add(string.format('<rect x="%d" y="%d" width="%.1f" height="%d" fill="%s" fill-opacity="0.8"/>\n',
        bar_x_start, bar_y, bar_width, bar_height, color))
      
      -- Value label (right side of bar)
      add(string.format('<text x="%.1f" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="10" fill="#333">%d</text>\n',
        bar_x_start + bar_width + 8, bar_y + bar_height/2 + 4, item.value))
    end
    
    y_pos = y_pos + (#top_5_http_codes * (bar_height + 8)) + 20
  end
  
  -- Section 9: MAC Layer Analysis - Force to new page
  local bottom_margin = 60
  local page_usable_height = paper.height - bottom_margin
  local current_page_num = math.floor(y_pos / paper.height)
  local padding = paper.height - (y_pos - (current_page_num * paper.height))
  add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
  y_pos = y_pos + padding + 80
  
  add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">9. MAC Layer Analysis</text>\n', y_pos))
  y_pos = y_pos + 30
  
  -- Traffic type (broadcast/multicast/unicast)
  local total_frames = mac_stats.broadcast + mac_stats.multicast + mac_stats.unicast
  if total_frames > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">9.1 Traffic Type Distribution</text>\n', y_pos))
    y_pos = y_pos + 20
    
    local traffic_types = {
      {label = "Unicast", value = mac_stats.unicast},
      {label = "Broadcast", value = mac_stats.broadcast},
      {label = "Multicast", value = mac_stats.multicast}
    }
    add(generate_pie_chart(traffic_types, "", paper.width/2, y_pos + 120, 100, true))
    y_pos = y_pos + 270
  end
  
  -- Frame sizes
  local frame_size_data = dict_to_sorted_array(mac_stats.frame_sizes, 10)
  if #frame_size_data > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">9.2 Frame Size Distribution</text>\n', y_pos))
    y_pos = y_pos + 30
    add(generate_bar_chart(frame_size_data, "", 50, y_pos, paper.width - 100, 200, false))
    y_pos = y_pos + 250
  end
  
  -- Top vendors
  local top_vendors = dict_to_sorted_array(mac_stats.vendors, 10)
  if #top_vendors > 0 then
    add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">9.3 Top 10 MAC Vendors</text>\n', y_pos))
    y_pos = y_pos + 20
    
    local vendor_table_data = {}
    for i, item in ipairs(top_vendors) do
      table.insert(vendor_table_data, {rank = i, vendor = item.label, count = item.value})
    end
    vendor_table_data = pad_table_data(vendor_table_data, 10)  -- Pad to 10 rows
    
    local vendor_cols = {
      {title = "#", field = "rank"},
      {title = "Vendor", field = "vendor"},
      {title = "Packets", field = "count"}
    }
    
    local vendor_svg, vendor_height = generate_table(vendor_table_data, "", 60, y_pos, paper.width - 120, vendor_cols)
    add(vendor_svg)
    y_pos = y_pos + vendor_height + 30
  end
  
  -- Section 10: IP Layer Analysis - Force to new page
  if ip_stats.total_packets > 0 then
    local bottom_margin = 60
    local page_usable_height = paper.height - bottom_margin
    local current_page_num = math.floor(y_pos / paper.height)
    local padding = paper.height - (y_pos - (current_page_num * paper.height))
    add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
    y_pos = y_pos + padding + 80
    
    add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">10. IP Layer Analysis</text>\n', y_pos))
    y_pos = y_pos + 30
    
    -- TTL distribution
    local ttl_data = dict_to_sorted_array(ip_stats.ttl, 10)
    if #ttl_data > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">10.1 TTL Distribution</text>\n', y_pos))
      y_pos = y_pos + 30
      add(generate_bar_chart(ttl_data, "", 50, y_pos, paper.width - 100, 200, false))
      y_pos = y_pos + 250
    end
    
    -- Fragmentation stats
    if ip_stats.fragmented > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">10.2 IP Fragmentation</text>\n', y_pos))
      y_pos = y_pos + 25
      add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Fragmented Packets: <tspan fill="#333" font-weight="700">%d</tspan></text>\n', y_pos, ip_stats.fragmented))
      y_pos = y_pos + 18
      local frag_pct = (ip_stats.fragmented / ip_stats.total_packets) * 100
      add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#555">Fragmentation Rate: <tspan fill="#333" font-weight="700">%.2f%%</tspan></text>\n', y_pos, frag_pct))
      y_pos = y_pos + 30
    else
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">10.2 IP Fragmentation</text>\n', y_pos))
      y_pos = y_pos + 25
      add(string.format('<text x="90" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="11" fill="#666">No IP fragmentation detected</text>\n', y_pos))
      y_pos = y_pos + 40
    end
    
    -- 10.3 DSCP Distribution
    local dscp_data = dict_to_sorted_array(ip_stats.dscp, 10)
    if #dscp_data > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">10.3 DSCP (Differentiated Services) Distribution</text>\n', y_pos))
      y_pos = y_pos + 25
      add(generate_pie_chart(dscp_data, "", paper.width/2, y_pos + 100, 90, true))
      y_pos = y_pos + 240
    end
    
    -- 10.4 IP Protocol Distribution
    local proto_data = dict_to_sorted_array(ip_stats.protocols, 10)
    if #proto_data > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">10.4 IP Protocol Distribution</text>\n', y_pos))
      y_pos = y_pos + 30
      add(generate_bar_chart(proto_data, "", 50, y_pos, paper.width - 100, 200, false))
      y_pos = y_pos + 250
    end
  end
  
  -- Section 11: TCP Analysis - Force to new page
  if tcp_stats.total_packets > 0 then
    local bottom_margin = 60
    local page_usable_height = paper.height - bottom_margin
    local current_page_num = math.floor(y_pos / paper.height)
    local padding = paper.height - (y_pos - (current_page_num * paper.height))
    add(string.format('<rect x="0" y="%d" width="1" height="%d" fill="none"/>\n', y_pos, padding))
    y_pos = y_pos + padding + 80
    
    add(string.format('<text x="50" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="18" font-weight="700" fill="#2C7BB6">11. TCP Analysis</text>\n', y_pos))
    y_pos = y_pos + 30
    
    -- Window size distribution
    local window_data = dict_to_sorted_array(tcp_stats.window_sizes, 10)
    if #window_data > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">11.1 TCP Window Size Distribution</text>\n', y_pos))
      y_pos = y_pos + 30
      add(generate_bar_chart(window_data, "", 50, y_pos, paper.width - 100, 200, false))
      y_pos = y_pos + 250
    end
    
    -- Segment size distribution
    local segment_data = dict_to_sorted_array(tcp_stats.segment_sizes, 10)
    if #segment_data > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">11.2 TCP Segment Size Distribution</text>\n', y_pos))
      y_pos = y_pos + 30
      add(generate_bar_chart(segment_data, "", 50, y_pos, paper.width - 100, 200, false))
      y_pos = y_pos + 250
    end
    
    -- RTT distribution
    local rtt_data = dict_to_sorted_array(tcp_stats.rtt_samples, 10)
    if #rtt_data > 0 then
      add(string.format('<text x="60" y="%d" font-family="Arial, Helvetica, sans-serif" font-size="14" font-weight="700" fill="#333">11.3 TCP Round-Trip Time Distribution</text>\n', y_pos))
      y_pos = y_pos + 30
      add(generate_bar_chart(rtt_data, "", 50, y_pos, paper.width - 100, 200, false))
      y_pos = y_pos + 250
    end
  end
  
  -- Update SVG height to actual content
  local final_height = y_pos + 50
  
  add('</svg>\n')
  
  local svg = table.concat(out)
  
  -- Extract just the inner content (between <svg> and </svg>) for multi-page export
  local svg_content_only = svg:match('<svg[^>]*>(.+)</svg>')
  -- Fix the SVG height in the already generated content
  svg = svg:gsub('height="'..math.max(paper.height, 3000)..'"', 'height="'..final_height..'"')
  svg = svg:gsub('viewBox="0 0 '..paper.width..' '..math.max(paper.height, 3000)..'"', 'viewBox="0 0 '..paper.width..' '..final_height..'"')
  
  local svg_path = tmp_svg()
  local fh, err = io.open(svg_path, "wb")
  if not fh then
    tw:append("Failed to write SVG: "..tostring(err).."\n")
    return
  end
  fh:write(svg)
  fh:close()
  
  tw:append("Detailed report generated: "..svg_path.."\n")
  tw:append(string.format("Total content height: %d px (%.1f pages)\n", final_height, final_height / paper.height))
  
  local tools = detect_converters()
  -- Only report if all dependencies are met, otherwise show what's missing
  local has_converter = tools.rsvg or tools.inkscape or tools.magick
  local has_combiner = tools.pdfunite or tools.pdftk
  if has_converter and has_combiner then
    tw:append("\n✓ All dependencies met - PDF export available\n")
  else
    tw:append("\n✗ Missing dependencies:\n")
    if not has_converter then
      tw:append("  - SVG converter: rsvg-convert, inkscape, or imagemagick\n")
      tw:append("    Install: brew install librsvg (recommended)\n")
    end
    if not has_combiner then
      tw:append("  - PDF combiner: pdfunite or pdftk\n")
      tw:append("    Install: brew install poppler (pdfunite) or pdftk-java\n")
    end
  end
  
  -- Determine paper size string for export
  local paper_size_name = paper.name == "Legal" and "Legal" or "A4"
  
  tw:add_button("Export PDF", function()
    export_multipage_pdf(svg_content_only, final_height, tw, tools, paper_size_name)
  end)
  
  tw:add_button("Open SVG", function()
    if not try_open_in_browser(svg_path) then
      tw:append("Could not auto-open; open the file manually.\n")
    end
  end)
end

------------------------------------------------------------
-- Wrapper functions for detailed report with different paper sizes
------------------------------------------------------------
local function generate_summary_report()
  generate_summary_report_internal()
end

local function generate_detailed_report_a4()
  current_paper_size = PAPER_SIZES.A4
  generate_detailed_report_internal()
end

local function generate_detailed_report_legal()
  current_paper_size = PAPER_SIZES.LEGAL
  generate_detailed_report_internal()
end

------------------------------------------------------------
-- Menu Registration
------------------------------------------------------------
register_menu("PacketReporter/1. Summary Report", generate_summary_report, MENU_TOOLS_UNSORTED)
register_menu("PacketReporter/2. Detailed Report (A4)", generate_detailed_report_a4, MENU_TOOLS_UNSORTED)
register_menu("PacketReporter/3. Detailed Report (Legal)", generate_detailed_report_legal, MENU_TOOLS_UNSORTED)

-- Check if Communication Matrix plugin is available
-- Look for the standalone menu registration
local function check_comm_matrix_installed()
  -- Check if the standalone plugin file exists in common plugin directories
  local plugin_name = "comm_matrix_table_view.lua"
  local home = get_home_dir()
  local check_paths = {
    home .. "/.local/lib/wireshark/plugins/" .. plugin_name,
    home .. "/.wireshark/plugins/" .. plugin_name,
    "/usr/lib/wireshark/plugins/" .. plugin_name,
    "/usr/local/lib/wireshark/plugins/" .. plugin_name
  }
  
  for _, path in ipairs(check_paths) do
    local f = io.open(path, "r")
    if f then
      f:close()
      return true
    end
  end
  return false
end

-- Only register Communication Matrix menu if plugin is installed
if check_comm_matrix_installed() then
  local function open_comm_matrix()
    local tw = TextWindow.new("Communication Matrix Info")
    tw:append("Communication Matrix Visualization\n")
    tw:append(string.rep("=", 50) .. "\n\n")
    tw:append("The Communication Matrix Report is available via:\n\n")
    tw:append("  Tools -> Communication Matrix Report\n\n")
    tw:append("This provides:\n")
    tw:append("  - IP Address circle visualization\n")
    tw:append("  - MAC Address circle visualization\n")
    tw:append("  - Top Conversations table\n")
    tw:append("  - Traffic analysis with color-coded flows\n")
  end
  
  register_menu("PacketReporter/4. Communication Matrix", open_comm_matrix, MENU_TOOLS_UNSORTED)
end

------------------------------------------------------------
-- Run Startup Dependency Check
------------------------------------------------------------
check_dependencies_on_startup()
