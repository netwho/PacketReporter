# PacketReporter v0.2.5 Release Summary

**Release Date:** January 16, 2026  
**Status:** Public Beta  
**Changes:** Bug fixes, documentation improvements, Windows support enhancements

## What's New in 0.2.5

### 🐛 Bug Fixes

#### IP Address Display in Top 10 Talkers Report
- **Issue:** IPv4 addresses were truncated (e.g., "192.168.5..." instead of full IP)
- **Solution:** 
  - Increased character limit from 12 to 15 characters
  - Implemented adaptive font sizing (9pt → 8pt → 7.5pt based on label length)
  - Full IPv4 addresses now display properly in both Summary and Detailed reports

#### Windows Prerequisites Checker Enhancement
- **Improved PDFtk Detection:**
  - Now checks system PATH first
  - Falls back to common installation paths (Program Files, Program Files (x86))
  - Better error messages for troubleshooting
- **Critical PATH Warning:**
  - Added prominent reminder to log off/on after PATH modifications
  - Prevents confusion about tools not being found immediately after installation

### 📖 Documentation Improvements

#### Windows Quick Install Manual (New)
- **English Version:** `WINDOWS_QUICK_INSTALL_MANUAL_en.html` / `.pdf`
- **German Version:** `WINDOWS_QUICK_INSTALL_MANUAL_de.html` / `.pdf`

**Features:**
- Professional 5-page installation guide
- Step-by-step rsvg-convert installation (Option A: System32, Option B: Custom PATH)
- Step-by-step PDFtk installation with critical warnings
- Prerequisites verification using PowerShell script
- Installation and configuration walkthrough
- Troubleshooting section for common issues
- Proper A4 page formatting with optimized spacing

### 📐 Page Layout Optimization
- Optimized margins and padding for A4 pages
- Improved section spacing to prevent orphaned content
- Better list density for comprehensive coverage
- Cleaner visual hierarchy

## File Changes

### New Files
```
installers/windows/
├── WINDOWS_QUICK_INSTALL_MANUAL_en.pdf       (382 KB)
└── WINDOWS_QUICK_INSTALL_MANUAL_de.pdf       (384 KB)
```

### Modified Files
```
packet_reporter.lua                   (IP address display fix)
check-prereqs.ps1                     (Enhanced PDFtk detection & warnings)
CHANGELOG.md                          (Added v0.2.5 release notes)
README.md                             (Updated version badge to 0.2.5)
```

## Installation & Testing Recommendations

### For Windows Users
1. Use the new Quick Install Manual (EN or DE)
2. Follow step-by-step installation of rsvg-convert and PDFtk
3. Run prerequisites checker: `powershell -ExecutionPolicy Bypass -File check-prereqs.ps1`
4. Verify all tools are found before proceeding

### For All Users
1. Update to v0.2.5 from latest release
2. Generate a test report to verify IP addresses display correctly
3. Check that all dependencies are found (run prereq checker on your platform)

## Known Limitations
- Windows: Brief console windows may appear during PDF generation (Lua limitation)
- PDF export requires external tools (rsvg-convert, pdftk, etc.)
- Windows PATH changes require log off/on to take effect

## Future Improvements
- Silent PDF generation on Windows
- Configurable top-N limits
- Additional protocol analysis modules
- Report templates and custom color schemes

---

**Questions or Issues?** Please report on GitHub: https://github.com/netwho/PacketReporter/issues
