# Contributing to PacketReporter

Thank you for considering contributing to PacketReporter! This document provides guidelines for contributing to the project.

## Getting Started

1. **Fork the repository** on GitHub: https://github.com/netwho/PacketReporter
2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR-USERNAME/PacketReporter.git
   cd PacketReporter
   ```
3. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites
- Wireshark 4.0 or later
- Lua 5.2+ (included with Wireshark)
- Git

### Testing Your Changes
1. Copy modified plugin to Wireshark plugins directory:
   ```bash
   cp packet_reporter.lua ~/.local/lib/wireshark/plugins/
   ```
2. Restart Wireshark
3. Test with various capture files
4. Verify PDF export functionality

## Code Style Guidelines

### Lua Conventions
- Use **2-space indentation**
- Use **snake_case** for functions and variables
- Use **UPPER_CASE** for constants
- Add comments for complex logic
- Keep functions focused and single-purpose

### Example
```lua
-- Good
local function calculate_statistics(packets)
  local total_bytes = 0
  for _, pkt in ipairs(packets) do
    total_bytes = total_bytes + pkt.size
  end
  return total_bytes
end

-- Avoid
local function doStuff(p)
  local x=0 for i,v in ipairs(p) do x=x+v.size end return x
end
```

## What to Contribute

### Bug Fixes
- Search existing issues first
- Create an issue describing the bug
- Submit a PR with fix and test case

### New Features
Ideal contributions:
- Additional protocol analysis (SMTP, FTP, SIP)
- New visualization types
- Performance improvements
- Documentation improvements

### Feature Request Process
1. Open an issue with feature proposal
2. Discuss implementation approach
3. Get approval before major work
4. Submit PR when ready

## Testing Guidelines

### Test Your Changes With
1. **Empty captures** - Should show "No data" messages
2. **Small captures** (< 1000 packets)
3. **Medium captures** (1000-10000 packets)
4. **Large captures** (> 10000 packets)
5. **Various protocols** - HTTP, DNS, TCP, UDP
6. **Display filters applied**

### Expected Behavior
- No Lua errors in Wireshark console
- Charts render correctly
- PDF export works (if converters installed)
- Reports complete within reasonable time

## Commit Guidelines

### Commit Message Format
```
type: Brief description (50 chars max)

Detailed explanation if needed (wrap at 72 chars)

Fixes #123
```

### Types
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style/formatting
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Build/tooling changes

### Examples
```
feat: Add SMTP analysis section

Added new data collection and visualization for SMTP traffic including:
- Top senders/recipients
- Mail server analysis
- Attachment statistics

Closes #45

---

fix: Handle empty DNS response field

Previously crashed when dns.resp.name was nil. Added nil check in
collect_dns_stats() function.

Fixes #67
```

## Pull Request Process

### Before Submitting
- [ ] Code follows style guidelines
- [ ] Tested with multiple capture files
- [ ] Documentation updated if needed
- [ ] No Lua errors in console
- [ ] Commit messages are clear

### PR Template
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement

## Testing
Describe testing performed

## Screenshots (if applicable)
Add screenshots of new features

## Checklist
- [ ] Code follows project style
- [ ] Self-reviewed code
- [ ] Commented complex sections
- [ ] Updated documentation
- [ ] No new warnings
- [ ] Tested with sample captures
```

## Architecture Guidelines

### Adding New Report Sections

1. **Create data collection function**
   ```lua
   local function collect_protocol_stats()
     local stats = {}
     local tap = Listener.new("protocol", nil)
     
     function tap.packet(pinfo, tvb)
       -- Extract data
     end
     
     retap_packets()
     tap:remove()
     return stats
   end
   ```

2. **Add visualization**
   ```lua
   -- In report generator
   local protocol_data = collect_protocol_stats()
   add(generate_bar_chart(protocol_data, "Title", x, y, w, h, true))
   ```

3. **Update section numbering** in detailed report

### Adding New Chart Types

Create new function following pattern:
```lua
local function generate_new_chart(data, title, x, y, width, height)
  local out = {}
  local function add(s) table.insert(out, s) end
  
  -- Generate SVG
  add('<g>...</g>\n')
  
  return table.concat(out)
end
```

## Documentation

### When to Update Docs
- New features → Update README.md
- API changes → Update PROJECT_OVERVIEW.md
- Quick tutorials → Update QUICKSTART.md
- Version changes → Update CHANGELOG.md

### Documentation Style
- Use clear, concise language
- Provide examples
- Include screenshots for visual features
- Keep line length < 100 characters

## Code Review Process

### What Reviewers Look For
- Code quality and style
- Potential bugs
- Performance impact
- Documentation completeness
- Test coverage

### Response Time
- We aim to review PRs within 7 days
- Large PRs may take longer

## Questions?

- Open an issue for questions
- Check existing issues/PRs first
- Be respectful and constructive

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to PacketReporter! 🎉
