# Enhanced DHCP Manager - Code Documentation

## Project Overview

The Enhanced DHCP Manager is a comprehensive OpenWrt application that provides advanced DHCP management capabilities through both a standalone HTML interface and LuCI integration. The project creates universal IPK packages that can run on all OpenWrt platforms without compatibility issues.

## Architecture

### Dual Interface Architecture
The application provides two interfaces:
1. **Standalone HTML Interface** (`/enhanced-dhcp/`) - Modern, dependency-free web app
2. **LuCI Integration** (`Network → Enhanced DHCP`) - Traditional OpenWrt admin interface

### Backend Architecture
- **CGI API Backend**: Shell-based API at `/cgi-bin/enhanced-dhcp-api`
- **UCI Configuration**: Standard OpenWrt configuration system
- **Init Script**: Service management and validation
- **Direct File Access**: Raw parsing of DHCP leases and ARP tables

## File Structure and Documentation

### Root Level Files

#### `build.sh`
**Purpose**: Main build script that creates the IPK package
**Key Features**:
- Validates all source files before building
- Creates proper IPK control files (control, postinst, prerm, conffiles)
- Sets correct file permissions for web and system files
- Generates documentation and test scripts
- Uses proper OpenWrt IPK format (gzipped tar, not ar archive)

**Build Process**:
1. Cleanup previous builds
2. Validate source files existence and permissions
3. Create package control files
4. Copy files with proper permissions
5. Build IPK using tar/gzip (OpenWrt standard)
6. Generate documentation and test scripts

#### `enhanced-dhcp/Makefile`
**Purpose**: OpenWrt package definition for integration builds
**Key Features**:
- Defines package metadata and dependencies
- Specifies installation paths and permissions
- Includes post-installation and pre-removal scripts
- Supports both OpenWrt build system and standalone builds

### Configuration Files

#### `enhanced-dhcp/files/etc/config/enhanced_dhcp`
**Purpose**: Main UCI configuration file
**Structure**:
```
config global 'global'
    option initialized '1'
    option version '2.0.0'
    option auto_discovery '1'
    option log_level 'info'

config settings 'settings'
    option enable_device_discovery '1'
    option discovery_interval '30'
    option auto_apply_default_tag '1'
    option backup_on_change '1'
    option max_backup_files '10'

config ui 'ui'
    option refresh_interval '30'
    option show_offline_devices '1'
    option show_lease_time '1'
    option compact_view '0'

config logging 'logging'
    option enable_audit_log '1'
    option log_tag_changes '1'
    option log_device_changes '1'
    option max_log_size '1024'
```

#### `enhanced-dhcp/files/etc/init.d/enhanced_dhcp`
**Purpose**: System service script for Enhanced DHCP Manager
**Key Functions**:
- `start_service()`: Initialize configuration and logging
- `stop_service()`: Clean shutdown
- `reload_service()`: Reload configuration and restart dnsmasq
- `validate_dhcp_config()`: Check for duplicate MACs and invalid tag references
- `setup_web_permissions()`: Ensure proper file permissions
- `log_message()`: Centralized logging with rotation
- `status()`: Service status information
- `health_check()`: Configuration validation

**Service Features**:
- Automatic configuration creation if missing
- DHCP configuration validation
- Log rotation based on size limits
- Web interface permission management
- Integration with system logger

### Backend API

#### `enhanced-dhcp/files/www/cgi-bin/enhanced-dhcp-api`
**Purpose**: Shell-based CGI API backend providing JSON endpoints
**Architecture**: Maximum compatibility design using only basic Linux commands

**API Endpoints**:
- `GET /leases` - Current DHCP leases from `/var/dhcp.leases`
- `GET /devices` - Combined device list (static hosts + ARP entries)
- `GET /tags` - DHCP tags from configuration
- `GET /stats` - System statistics (tag/device counts)
- `GET /arp` - ARP table entries
- `POST /apply_tag` - Apply DHCP tag to device

**Key Functions**:
- `parse_dhcp_hosts_simple()`: Parse UCI DHCP host configurations
- `parse_dhcp_tags_simple()`: Parse UCI DHCP tag configurations  
- `parse_dhcp_leases()`: Parse DHCP leases file
- `parse_arp_table()`: Parse ARP table from `/proc/net/arp`
- `get_devices()`: Combine static and discovered devices
- `apply_tag()`: Update device DHCP tag configuration

**Compatibility Features**:
- No UCI/LuCI dependencies (falls back to direct file parsing)
- Basic shell commands only (sed, grep, cut, etc.)
- JSON responses with error handling
- URL parameter parsing for GET/POST requests

### Frontend - Standalone HTML Interface

#### `enhanced-dhcp/files/www/enhanced-dhcp/index.html`
**Purpose**: Main HTML interface for standalone web application
**Features**:
- Single-page application with tabbed interface
- Responsive design for mobile devices
- Real-time data updates
- Professional UI with modern styling

**Structure**:
- Overview tab: Statistics and current DHCP leases
- Devices tab: Device management and tag assignment
- Tags tab: DHCP tag configuration

#### `enhanced-dhcp/files/www/enhanced-dhcp/script.js`
**Purpose**: JavaScript frontend logic
**Key Classes**:
- `EnhancedDHCPManager`: Main application controller

**Key Features**:
- API communication with error handling
- Tab management and navigation
- Real-time data refresh (30-second intervals)
- Device type detection and classification
- Tag assignment interface
- Mobile-responsive design

**API Integration**:
- Fetches data from CGI backend
- Handles loading states and errors
- Provides user feedback for operations

#### `enhanced-dhcp/files/www/enhanced-dhcp/style.css`
**Purpose**: Modern CSS styling for standalone interface
**Features**:
- Professional color scheme
- Mobile-first responsive design
- Card-based layout for statistics
- Table styling with hover effects
- Loading and error state styling

#### `enhanced-dhcp/files/www/enhanced-dhcp/device-types.json`
**Purpose**: Device classification database
**Structure**:
- `mac_prefixes`: MAC address to vendor mapping
- `device_categories`: Device type classification by keywords
- `default_tags`: Default DHCP tags for device types

**Usage**: Helps automatically classify devices and suggest appropriate DHCP tags

### Frontend - LuCI Integration

#### `enhanced-dhcp/files/usr/lib/lua/luci/controller/enhanced_dhcp.lua`
**Purpose**: LuCI controller for integration with OpenWrt admin interface
**Features**:
- Creates menu entry in Network section
- Template-based rendering
- Removes ACL dependencies for broader compatibility

#### `enhanced-dhcp/files/usr/lib/lua/luci/view/enhanced_dhcp.htm`
**Purpose**: LuCI template with embedded HTML interface
**Architecture**: Self-contained template with inline CSS and JavaScript

**Features**:
- Professional styling matching LuCI design
- Complete tabbed interface (Overview, Devices, Tags)
- API integration with error handling
- Responsive design for mobile access
- Same functionality as standalone interface

**Integration Method**: Embeds the complete interface directly in LuCI using template inheritance

### Security and Permissions

#### `enhanced-dhcp/files/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp.json`
**Purpose**: Access Control List definitions for LuCI integration
**Permissions**:
- **Read Access**: UCI configs, DHCP leases, ARP table, configuration files
- **Write Access**: UCI configs, configuration files
- **Execute Access**: Service control scripts (dnsmasq, enhanced_dhcp)

## Build System

### Package Creation Process
1. **Validation**: Check all required files exist and have correct permissions
2. **Control Files**: Generate package metadata, installation/removal scripts
3. **File Copying**: Copy source files with proper permissions
4. **IPK Creation**: Use standard OpenWrt format (tar.gz, not ar)
5. **Documentation**: Generate README and test scripts

### Installation Process
1. **Package Installation**: Standard `opkg install` process
2. **Post-Installation**: 
   - Enable CGI support in uhttpd
   - Set file permissions
   - Start Enhanced DHCP service
   - Display success message with access URL

### File Permissions
- **Web Files**: 644 (HTML, CSS, JS, JSON)
- **Executable Scripts**: 755 (CGI API, init script)
- **Configuration Files**: 644 (UCI configs)

## Testing and Deployment

### Automated Testing
The `build.sh` script generates validation scripts, and `test.sh` provides remote testing which validates:
1. Package installation status
2. Web interface file existence
3. CGI script permissions
4. UCI configuration accessibility
5. Init script functionality
6. API endpoint responsiveness
7. File readability

### Deployment Workflow
1. Build IPK package using `./build.sh`
2. Deploy to target device via SCP
3. Install using `opkg install`
4. Run automated tests
5. Verify web interface accessibility

## Compatibility Strategy

### LuCI Independence
- **No LuCI Dependencies**: Standalone HTML interface works without LuCI
- **Dual Interface**: Both standalone and LuCI-integrated interfaces
- **Fallback Mechanisms**: API falls back to direct file parsing if UCI unavailable

### OpenWrt Compatibility
- **Universal Package**: Architecture-independent (shell scripts, HTML, CSS, JS)
- **Basic Commands Only**: Uses standard Linux utilities available on all systems
- **Version Independence**: No specific OpenWrt version dependencies

### Error Handling
- **Graceful Degradation**: Functions continue working even if some features unavailable
- **Comprehensive Logging**: Detailed error logging for troubleshooting
- **User Feedback**: Clear error messages in web interface

## Security Considerations

### Input Validation
- **MAC Address Validation**: Regex validation for proper MAC format
- **Parameter Sanitization**: Basic URL parameter parsing and validation
- **File Access Control**: Limited to specific system files

### Access Control
- **LuCI ACL Integration**: Proper permission definitions
- **File Permissions**: Restrictive permissions on configuration files
- **Service Isolation**: Runs as system service with limited privileges

### Data Protection
- **No Sensitive Data Exposure**: No passwords or keys in configuration
- **Log Rotation**: Prevents log files from growing too large
- **Configuration Backup**: Automatic backup of configuration changes

## Development Patterns

### Shell Scripting Patterns
- **Function-based Architecture**: Modular functions for each operation
- **Error Handling**: Consistent error checking and logging
- **Compatibility Functions**: Fallback implementations for missing utilities

### Web Development Patterns  
- **Progressive Enhancement**: Basic functionality works, enhanced features add value
- **API-First Design**: Clean separation between frontend and backend
- **Responsive Design**: Mobile-first approach with desktop enhancements

### Configuration Management
- **UCI Integration**: Standard OpenWrt configuration patterns
- **Default Values**: Sensible defaults for all configuration options
- **Validation**: Configuration validation on service start

This documentation provides a comprehensive understanding of the Enhanced DHCP Manager codebase, its architecture, and implementation details for future development and maintenance.