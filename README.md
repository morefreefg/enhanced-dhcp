# Enhanced DHCP Manager for OpenWrt

A comprehensive DHCP options management system for OpenWrt that provides a web interface to create and manage DHCP option templates (tags) and assign them to network devices.

## Features

### ✨ Core Functionality
- **DHCP Tag Management**: Create and manage DHCP option templates
- **Device Management**: Assign different gateway and DNS settings per device  
- **Web Interface**: User-friendly LuCI-based management interface
- **Auto-Discovery**: Automatically discover network devices
- **Tag Assignment**: Quick assignment of DHCP tags to multiple devices

### 🔧 Technical Features
- **UCI Integration**: Native OpenWrt configuration management
- **dnsmasq Integration**: Works with existing DHCP server
- **Configuration Backup**: Automatic backup of configuration changes
- **Audit Logging**: Track all configuration changes
- **Cross-Platform**: Compatible with all OpenWrt architectures

### 🌐 Web Interface Components
- **Overview Dashboard**: System status and statistics
- **DHCP Tags**: Create and edit DHCP option templates
- **Device Management**: View and manage all network devices
- **Quick Assignment**: Bulk tag assignment tools

## Architecture

### Directory Structure
```
enhanced-dhcp/
├── Makefile                        # OpenWrt package build configuration
├── CONTROL/                        # IPK package control files
│   ├── control                     # Package metadata
│   ├── postinst                    # Post-installation script
│   └── prerm                       # Pre-removal script
└── files/                          # Files to be installed
    ├── etc/
    │   ├── config/enhanced_dhcp     # Default configuration
    │   └── init.d/enhanced_dhcp     # Service initialization script
    └── usr/
        ├── lib/lua/luci/            # LuCI web interface components
        │   ├── controller/dhcp_manager/main.lua    # URL routing
        │   ├── model/cbi/dhcp_manager/             # Form management
        │   │   ├── tags.lua         # DHCP tags management
        │   │   └── devices.lua      # Device management
        │   └── view/dhcp_manager/   # HTML templates
        │       ├── overview.htm     # Dashboard template
        │       ├── device_discovery.htm  # Device discovery
        │       ├── devices_js.htm   # JavaScript functionality
        │       └── quick_assign.htm # Quick assignment interface
        └── share/dhcp_manager/
            └── device_types.json    # Device type database
```

### Component Overview

#### 1. LuCI Controller (`main.lua`)
- URL routing and page management
- AJAX handlers for device operations
- DHCP lease management
- Tag application API

#### 2. CBI Models
- **`tags.lua`**: DHCP tag creation and management forms
- **`devices.lua`**: Device configuration and tag assignment

#### 3. View Templates
- **`overview.htm`**: System dashboard with statistics
- **`device_discovery.htm`**: Auto-discovery interface
- **`devices_js.htm`**: Client-side JavaScript functionality
- **`quick_assign.htm`**: Bulk operations interface

#### 4. Configuration Management
- UCI-based configuration storage
- Integration with OpenWrt DHCP system
- Automatic backup and restore

## DHCP Tag System

### Tag Structure
DHCP tags are stored in `/etc/config/dhcp` using UCI format:

```
config tag 'office_network'
    list dhcp_option '3,192.168.1.1'      # Gateway
    list dhcp_option '6,8.8.8.8,8.8.4.4'  # DNS servers

config tag 'guest_network'
    list dhcp_option '3,192.168.2.1'      # Gateway  
    list dhcp_option '6,1.1.1.1,1.0.0.1'  # DNS servers
```

### Device Assignment
Devices are assigned tags through UCI host entries:

```
config host
    option name 'laptop01'
    option mac '00:11:22:33:44:55'
    option tag 'office_network'
    option ip '192.168.1.100'    # Optional static IP
```

## Security Features

### Input Validation
- MAC address format validation and normalization
- Tag name validation (alphanumeric, underscore, hyphen only)
- IP address validation
- Reserved name protection

### Access Control
- LuCI ACL integration
- Configuration file permissions
- Log file access restrictions

### Audit Trail
- All configuration changes logged
- Device tag assignments tracked
- System integration events recorded

## Installation

### Building the IPK

1. **Quick Build** (for testing):
   ```bash
   ./quick-build.sh
   ```

2. **Full Build** (with validation):
   ```bash
   ./build-ipk.sh
   ```

### Installation on OpenWrt

1. **Copy IPK to router**:
   ```bash
   scp output/enhanced-dhcp_1.0.0-1_all.ipk root@192.168.1.1:/tmp/
   ```

2. **Install package**:
   ```bash
   opkg install /tmp/enhanced-dhcp_1.0.0-1_all.ipk
   ```

3. **Access web interface**:
   - Navigate to `Network` → `Enhanced DHCP` in LuCI

## Configuration

### Default Settings
The package creates default configuration in `/etc/config/enhanced_dhcp`:

```
config global 'global'
    option initialized '1'
    option version '1.0.0'
    option auto_discovery '1'
    option log_level 'info'

config settings 'settings'
    option enable_device_discovery '1'
    option discovery_interval '30'
    option auto_apply_default_tag '1'
    option backup_on_change '1'
    option max_backup_files '10'
```

### Service Management

```bash
# Start/stop service
/etc/init.d/enhanced_dhcp start
/etc/init.d/enhanced_dhcp stop

# Enable/disable auto-start
/etc/init.d/enhanced_dhcp enable
/etc/init.d/enhanced_dhcp disable

# Configuration reload
/etc/init.d/enhanced_dhcp reload

# Status check
/etc/init.d/enhanced_dhcp status

# Health check
/etc/init.d/enhanced_dhcp health
```

## Dependencies

### Required Packages
- `luci-base`: LuCI web framework
- `dnsmasq`: DHCP server (usually pre-installed)
- `uci`: Configuration management (usually pre-installed)

### Development Dependencies
- `binutils` (for `ar` command)
- `tar` and `gzip` (for archive creation)

## API Reference

### AJAX Endpoints

#### Get Devices
```
GET /cgi-bin/luci/admin/network/enhanced_dhcp/ajax_get_devices
```
Returns list of all network devices with their current configuration.

#### Apply Tag
```
POST /cgi-bin/luci/admin/network/enhanced_dhcp/ajax_apply_tag
```
Parameters:
- `mac`: Device MAC address
- `tag`: DHCP tag to apply
- `name`: Device name (optional)

#### Get DHCP Leases
```
GET /cgi-bin/luci/admin/network/enhanced_dhcp/ajax_get_leases
```
Returns current DHCP lease information.

## Contributing

### Code Style
- Follow OpenWrt Lua coding conventions
- Use proper error handling and validation
- Include comprehensive logging
- Maintain security best practices

### Testing
- Test on multiple OpenWrt versions
- Verify cross-architecture compatibility
- Validate all input fields
- Test backup/restore functionality

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, feature requests, or contributions:
- GitHub Issues: [enhanced-dhcp/enhanced-dhcp](https://github.com/enhanced-dhcp/enhanced-dhcp)
- Documentation: [Wiki](https://github.com/enhanced-dhcp/enhanced-dhcp/wiki)

## Changelog

### Version 1.0.0
- Initial release
- DHCP tag management
- Device discovery and assignment
- Web interface
- Configuration backup
- Audit logging