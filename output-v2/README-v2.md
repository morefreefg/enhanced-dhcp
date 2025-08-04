# Enhanced DHCP Manager v2.0 - HTML Edition

## Overview
This is a complete rewrite of the Enhanced DHCP Manager using pure HTML/CSS/JavaScript frontend and shell-based CGI backend, eliminating all LuCI dependencies and compatibility issues.

## Key Improvements in v2.0
- **No LuCI Dependencies**: Pure HTML frontend eliminates LuCI compatibility issues
- **Modern Web Technologies**: Responsive design with modern JavaScript
- **Better Performance**: Lightweight CGI backend with efficient API design
- **Universal Compatibility**: Works on all OpenWrt versions (19.07+)
- **Improved Maintainability**: Clean separation of frontend and backend

## Installation
```bash
opkg install luci-app-enhanced-dhcp-v2_2.0.0-1_all.ipk
```

## Web Interface
Access the interface at: http://[router-ip]/enhanced-dhcp/

## Features
- Real-time DHCP lease monitoring
- Device auto-discovery and classification
- DHCP tag management for network policies
- Responsive mobile-friendly interface
- No external dependencies

## Architecture
- **Frontend**: Pure HTML/CSS/JS single-page application
- **Backend**: Shell-based CGI script (`/www/cgi-bin/enhanced-dhcp-api`)
- **Data Sources**: Direct DHCP leases file parsing + UCI commands
- **Configuration**: Standard UCI configuration system

## API Endpoints
- GET /cgi-bin/enhanced-dhcp-api/devices - List all devices
- GET /cgi-bin/enhanced-dhcp-api/tags - List DHCP tags
- GET /cgi-bin/enhanced-dhcp-api/leases - Current DHCP leases
- GET /cgi-bin/enhanced-dhcp-api/stats - System statistics
- POST /cgi-bin/enhanced-dhcp-api/apply_tag - Apply tag to device
- POST /cgi-bin/enhanced-dhcp-api/create_tag - Create new tag
- POST /cgi-bin/enhanced-dhcp-api/delete_tag - Delete tag

## Configuration Files
- `/etc/config/enhanced_dhcp` - Main configuration
- `/etc/init.d/enhanced_dhcp` - Init script

## Compatibility
- OpenWrt 19.07+
- All architectures (universal package)
- No LuCI version dependencies

## Build Information
- Version: 2.0.0
- Build Date: Mon Aug  4 18:53:00 CST 2025
- Package Size:  20K
