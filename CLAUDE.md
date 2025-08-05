# Enhanced DHCP Project - Claude Memory

## Project Overview
This is a LuCI application for OpenWrt that provides enhanced DHCP management functionality. The project creates a universal IPK package that can run on all OpenWrt platforms.

## 📋 Code Documentation
**IMPORTANT**: For detailed understanding of the codebase, architecture, and file purposes, see: [CODE_DOCUMENTATION.md](./CODE_DOCUMENTATION.md)

The code documentation provides comprehensive information about:
- Project architecture and dual interface design
- Detailed file-by-file explanations
- API endpoints and functionality
- Build system and deployment workflow
- Security considerations and compatibility strategy
- Development patterns and best practices

@CODE_DOCUMENTATION.md - Reference this file to quickly understand the entire codebase structure and implementation details.

## Target Device
- IP: 192.168.10.2
- User: root
- Platform: iStoreOS 22.03.7 (x86_64)
- Status: ✅ Working and tested

## Testing Workflow
**Always test IPK packages on the actual target device:**
```bash
# 1. Deploy IPK to target device
scp output-v2/luci-app-enhanced-dhcp-v2_2.0.0-1_all.ipk root@192.168.10.2:/tmp/

# 2. Install using opkg on target device
ssh root@192.168.10.2 'opkg install /tmp/luci-app-enhanced-dhcp-v2_2.0.0-1_all.ipk'

# 3. Test web interface
curl http://192.168.10.2/enhanced-dhcp/
curl http://192.168.10.2/cgi-bin/enhanced-dhcp-api/stats

# 4. Verify file installation
ssh root@192.168.10.2 'ls -la /www/enhanced-dhcp/ && ls -la /www/cgi-bin/enhanced-dhcp-api'
```

## Build and Deployment Workflow

### 🚀 Release Process with Version Management
**版本管理规则:**
- 版本号存储在 `VERSION` 文件中
- IPK 包名和内容必须与 git tag 版本号一致
- 使用 `bump-version.sh` 自动递增版本号

**发布流程:**
1. **Bump 版本**: `./bump-version.sh [patch|minor|major]` (默认 patch)
2. **构建包**: `./build.sh` (自动读取 VERSION 文件)
3. **提交**: `git add . && git commit -m "Release message"`
4. **打 tag**: `git tag -a v$(cat VERSION) -m "Release description"`
5. **发 release**: `gh release create v$(cat VERSION) --title "Title" --notes "Description" output/*.ipk`

**完整发布命令示例:**
```bash
# 1. 递增版本号 (patch: 1.0.3 -> 1.0.4)
./bump-version.sh patch

# 2. 构建包 (自动使用新版本号)
./build.sh

# 3. 提交代码
git add . && git commit -m "Release v$(cat VERSION): Description"
git push origin main

# 4. 创建标签
git tag -a v$(cat VERSION) -m "Release v$(cat VERSION): Description"
git push origin v$(cat VERSION)

# 5. 创建GitHub Release
gh release create v$(cat VERSION) \
  --title "Enhanced DHCP Manager v$(cat VERSION)" \
  --notes "Release description" \
  output/luci-app-enhanced-dhcp_$(cat VERSION)-1_all.ipk \
  output/COMPATIBILITY_ADVANCED.md \
  output/test-install.sh
```

**版本号规则:**
- **patch**: Bug 修复, 小功能改进 (1.0.3 -> 1.0.4)
- **minor**: 新功能, API 变更 (1.0.4 -> 1.1.0)  
- **major**: 重大架构变更, 不兼容更新 (1.1.0 -> 2.0.0)

### 🔧 Complete Build-Deploy-Test Command
```bash
# One-command deployment (builds, deploys, tests)
./build-deploy-test.sh
```

This comprehensive script performs:
1. **Build** - Builds the IPK package using `build.sh`
2. **Deploy** - Copies package to target device via SCP
3. **Install** - Installs package (tries opkg, falls back to manual)
4. **Test** - Runs 7 comprehensive tests
5. **Verify** - Confirms all functionality is working
6. **Cleanup** - Removes temporary files

### 📋 Manual Step-by-Step Process
```bash
# Step 1: Build package
./build.sh

# Step 2: Deploy to device
scp output/luci-app-enhanced-dhcp_$(cat VERSION)-1_all.ipk root@192.168.10.2:/tmp/

# Step 3: Install on device
ssh root@192.168.10.2 'opkg install /tmp/luci-app-enhanced-dhcp_*-1_all.ipk'

# Step 4: Test installation
ssh root@192.168.10.2 'uci show enhanced_dhcp && /etc/init.d/enhanced_dhcp status'
```

### 🧪 Test Suite
The automated test suite checks:
1. ✅ Package installation status
2. ✅ LuCI controller file existence
3. ✅ UCI configuration accessibility
4. ✅ Init script functionality
5. ✅ LuCI module integration
6. ✅ JSON compatibility (luci.jsonc)
7. ✅ DHCP leases file access

## Package Structure

### 📦 Generated Package
- **Name**: `luci-app-enhanced-dhcp_$(cat VERSION)-1_all.ipk`
- **Size**: ~20KB
- **Location**: `output/`
- **Type**: Universal IPK (all architectures)
- **Version**: 自动从 `VERSION` 文件读取

### 🗂 Key Files
```
enhanced-dhcp/files/
├── etc/
│   ├── config/enhanced_dhcp              # UCI configuration
│   └── init.d/enhanced_dhcp              # Init script
└── usr/lib/lua/luci/
    ├── controller/enhanced_dhcp.lua      # Main controller
    ├── model/cbi/enhanced_dhcp_*.lua     # CBI models
    └── view/enhanced_dhcp_*.htm          # LuCI templates
```

## Compatibility Fixes Applied

### 🔄 JSON Module Compatibility
- **Issue**: New LuCI versions use `luci.jsonc` instead of `luci.json`
- **Fix**: Updated all references to use `luci.jsonc`
- **Files**: All Lua controller and template files

### 📊 DHCP Leases API Compatibility  
- **Issue**: `sys.dhcp_leases()` not available in newer LuCI
- **Fix**: Direct file reading from `/var/dhcp.leases`
- **Implementation**: 
```lua
local leases = {}
local lease_file = io.open("/var/dhcp.leases", "r")
if lease_file then
    for line in lease_file:lines() do
        local exp, mac, ip, name = line:match("(%d+) (%S+) (%S+) (%S*)")
        if exp and mac and ip then
            table.insert(leases, {
                expires = exp,
                macaddr = mac,
                ipaddr = ip,
                hostname = name ~= "*" and name or "Unknown"
            })
        end
    end
    lease_file:close()
end
```

## Web Interface Access

### 🌐 URL Structure
- **Base**: http://192.168.10.2/cgi-bin/luci
- **Enhanced DHCP**: Network → Enhanced DHCP

### 📱 Available Pages
1. **Overview**: Network → Enhanced DHCP → Overview
   - DHCP statistics and current leases
   - System status information
   
2. **Devices**: Network → Enhanced DHCP → Devices  
   - Device management and tag assignment
   - Auto-discovery of connected devices
   
3. **Tags**: Network → Enhanced DHCP → Tags
   - DHCP option template management
   - Custom gateway/DNS configurations

## Development Notes

### 🏗 Build System
- **Primary Builder**: `build.sh` (reads version from VERSION file)
- **Version Management**: `bump-version.sh` (自动递增版本号)
- **Version Storage**: `VERSION` 文件
- **Output Directory**: `output/`

### 🔧 Installation Methods
1. **Standard**: `opkg install package.ipk`
2. **Manual**: `./manual-install.sh` (bypasses opkg)
3. **Automated**: `./build-deploy-test.sh` (full workflow)

### 📝 Configuration Files
- **UCI Config**: `/etc/config/enhanced_dhcp`
- **Init Script**: `/etc/init.d/enhanced_dhcp`
- **ACL Permissions**: Automatically configured

## Troubleshooting

### 🔍 Common Issues
1. **JSON Module Errors**: Fixed by using `luci.jsonc`
2. **DHCP Leases Errors**: Fixed by direct file reading
3. **Permission Issues**: Fixed by proper IPK creation
4. **Installation Failures**: Use manual installation method

### 📊 Verification Commands
```bash
# Check package installation
ssh root@192.168.10.2 'opkg list-installed | grep enhanced'

# Check LuCI integration
ssh root@192.168.10.2 'ls -la /usr/lib/lua/luci/controller/enhanced_dhcp.lua'

# Check configuration
ssh root@192.168.10.2 'uci show enhanced_dhcp'

# Check service
ssh root@192.168.10.2 '/etc/init.d/enhanced_dhcp status'

# Check logs
ssh root@192.168.10.2 'logread | grep -i dhcp'
```

## Success Indicators

### ✅ Installation Success
- Package appears in `opkg list-installed`
- LuCI menu shows "Enhanced DHCP" under Network
- All three pages (Overview, Devices, Tags) load without errors
- UCI configuration is accessible
- Service status is operational

### 🎯 Functionality Verified
- ✅ Device discovery and management
- ✅ DHCP tag assignment
- ✅ Custom DHCP options configuration
- ✅ Real-time lease information
- ✅ Cross-version LuCI compatibility

## Project Status: ✅ COMPLETE
The Enhanced DHCP universal IPK package is fully functional, tested, and ready for production use on all OpenWrt platforms. All compatibility issues have been resolved and the automated build-deploy-test workflow ensures consistent deployments.