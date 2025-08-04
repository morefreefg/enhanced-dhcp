#!/bin/bash

# Enhanced DHCP Manager v2.0 - HTML Edition Build Script
# Builds a LuCI-independent IPK package for all OpenWrt platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="enhanced-dhcp-v2"
VERSION="2.0.0"
PACKAGE_NAME="luci-app-enhanced-dhcp-v2"
BUILD_DIR="$SCRIPT_DIR/build-v2"
OUTPUT_DIR="$SCRIPT_DIR/output-v2"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Cleanup previous builds
cleanup() {
    log_info "Cleaning up previous builds..."
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
}

# Validate source files
validate_sources() {
    log_info "Validating source files..."
    
    local required_files=(
        "$SCRIPT_DIR/$PROJECT_NAME/Makefile"
        "$SCRIPT_DIR/$PROJECT_NAME/files/www/cgi-bin/enhanced-dhcp-api"
        "$SCRIPT_DIR/$PROJECT_NAME/files/www/enhanced-dhcp/index.html"
        "$SCRIPT_DIR/$PROJECT_NAME/files/www/enhanced-dhcp/style.css"
        "$SCRIPT_DIR/$PROJECT_NAME/files/www/enhanced-dhcp/script.js"
        "$SCRIPT_DIR/$PROJECT_NAME/files/etc/config/enhanced_dhcp"
        "$SCRIPT_DIR/$PROJECT_NAME/files/etc/init.d/enhanced_dhcp"
        "$SCRIPT_DIR/$PROJECT_NAME/files/usr/lib/lua/luci/controller/enhanced_dhcp_v2.lua"
        "$SCRIPT_DIR/$PROJECT_NAME/files/usr/lib/lua/luci/view/enhanced_dhcp_v2.htm"
        "$SCRIPT_DIR/$PROJECT_NAME/files/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp-v2.json"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log_error "Required file missing: $file"
            exit 1
        fi
    done
    
    # Check CGI script is executable
    if [[ ! -x "$SCRIPT_DIR/$PROJECT_NAME/files/www/cgi-bin/enhanced-dhcp-api" ]]; then
        log_error "CGI script is not executable"
        exit 1
    fi
    
    # Check init script is executable
    if [[ ! -x "$SCRIPT_DIR/$PROJECT_NAME/files/etc/init.d/enhanced_dhcp" ]]; then
        log_error "Init script is not executable"
        exit 1
    fi
    
    log_success "Source validation completed"
}

# Create control file
create_control_file() {
    log_info "Creating package control file..."
    
    mkdir -p "$BUILD_DIR/CONTROL"
    
    cat > "$BUILD_DIR/CONTROL/control" << EOF
Package: $PACKAGE_NAME
Version: $VERSION-1
Description: Enhanced DHCP Manager v2.0 - HTML Edition
 A modern, LuCI-independent DHCP management interface built with pure HTML/CSS/JS.
 .
 Features:
 - Pure HTML frontend (no LuCI dependencies)
 - Real-time DHCP lease monitoring  
 - Device auto-discovery and classification
 - DHCP tag management for different network policies
 - Responsive web interface
 - Compatible with all OpenWrt versions
 .
 This version eliminates LuCI compatibility issues by using a standalone
 CGI backend and modern web technologies for the frontend.
Section: luci
Priority: optional
Maintainer: Enhanced DHCP Team <support@enhanced-dhcp.org>
License: MIT
Architecture: all
Installed-Size: $(du -sb "$SCRIPT_DIR/$PROJECT_NAME/files" | cut -f1)
Depends: uhttpd, uhttpd-mod-ubus
Source: N/A
SourceName: $PACKAGE_NAME
EOF

    log_success "Control file created"
}

# Create post-installation script
create_postinst_script() {
    log_info "Creating post-installation script..."
    
    cat > "$BUILD_DIR/CONTROL/postinst" << 'EOF'
#!/bin/sh

echo "Configuring Enhanced DHCP Manager v2.0..."

# Enable and start the service
/etc/init.d/enhanced_dhcp enable 2>/dev/null || true
/etc/init.d/enhanced_dhcp start 2>/dev/null || true

# Set up web server configuration if needed
if [ -f /etc/config/uhttpd ]; then
    # Ensure CGI support is enabled
    if ! uci -q get uhttpd.main.cgi_prefix >/dev/null 2>&1; then
        uci set uhttpd.main.cgi_prefix='/cgi-bin'
        uci commit uhttpd
        /etc/init.d/uhttpd restart 2>/dev/null || true
    fi
fi

echo "Enhanced DHCP Manager v2.0 installed successfully!"
echo "Access the web interface at: http://[router-ip]/enhanced-dhcp/"
echo ""
echo "Key improvements in v2.0:"
echo "- No LuCI dependencies (eliminates compatibility issues)"
echo "- Modern HTML/CSS/JS frontend"
echo "- Better performance and stability"
echo "- Compatible with all OpenWrt versions"

exit 0
EOF

    chmod +x "$BUILD_DIR/CONTROL/postinst"
    log_success "Post-installation script created"
}

# Create pre-removal script
create_prerm_script() {
    log_info "Creating pre-removal script..."
    
    cat > "$BUILD_DIR/CONTROL/prerm" << 'EOF'
#!/bin/sh

echo "Stopping Enhanced DHCP Manager v2.0..."

# Stop and disable the service
/etc/init.d/enhanced_dhcp stop 2>/dev/null || true
/etc/init.d/enhanced_dhcp disable 2>/dev/null || true

exit 0
EOF

    chmod +x "$BUILD_DIR/CONTROL/prerm"
    log_success "Pre-removal script created"
}

# Create configuration files list
create_conffiles() {
    log_info "Creating configuration files list..."
    
    cat > "$BUILD_DIR/CONTROL/conffiles" << EOF
/etc/config/enhanced_dhcp
EOF

    log_success "Configuration files list created"
}

# Copy package files
copy_package_files() {
    log_info "Copying package files..."
    
    # Copy all files maintaining directory structure
    cp -r "$SCRIPT_DIR/$PROJECT_NAME/files/"* "$BUILD_DIR/"
    
    # Ensure proper permissions
    find "$BUILD_DIR" -type f -name "*.html" -exec chmod 644 {} \;
    find "$BUILD_DIR" -type f -name "*.css" -exec chmod 644 {} \;
    find "$BUILD_DIR" -type f -name "*.js" -exec chmod 644 {} \;
    find "$BUILD_DIR" -type f -name "*.json" -exec chmod 644 {} \;
    find "$BUILD_DIR" -type f -path "*/config/*" -exec chmod 644 {} \;
    find "$BUILD_DIR" -type f -path "*/init.d/*" -exec chmod 755 {} \;
    find "$BUILD_DIR" -type f -path "*/cgi-bin/*" -exec chmod 755 {} \;
    find "$BUILD_DIR" -type f -name "*.lua" -exec chmod 644 {} \;
    find "$BUILD_DIR" -type f -name "*.htm" -exec chmod 644 {} \;
    
    log_success "Package files copied with correct permissions"
}

# Build IPK package
build_ipk() {
    log_info "Building IPK package..."
    
    local package_file="${PACKAGE_NAME}_${VERSION}-1_all.ipk"
    
    # Create the IPK package using ar (OpenWrt standard)
    cd "$BUILD_DIR"
    
    # Create data.tar.gz (all files except CONTROL, with proper paths)
    tar --exclude='./CONTROL' -czf data.tar.gz ./etc ./www ./usr
    
    # Create control.tar.gz (CONTROL directory contents)
    cd CONTROL
    tar -czf ../control.tar.gz ./*
    cd ..
    
    # Create debian-binary file
    echo "2.0" > debian-binary
    
    # Create the final IPK file using gzipped tar (correct OpenWrt format)
    # OpenWrt IPK files are gzipped tar archives, not ar archives
    tar --owner=0 --group=0 -cf "${package_file}.tar" debian-binary control.tar.gz data.tar.gz
    gzip "${package_file}.tar"
    mv "${package_file}.tar.gz" "$OUTPUT_DIR/$package_file"
    
    cd "$SCRIPT_DIR"
    
    local file_size=$(du -h "$OUTPUT_DIR/$package_file" | cut -f1)
    log_success "IPK package built: $package_file ($file_size)"
}

# Generate documentation
generate_documentation() {
    log_info "Generating documentation..."
    
    cat > "$OUTPUT_DIR/README-v2.md" << EOF
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
\`\`\`bash
opkg install luci-app-enhanced-dhcp-v2_${VERSION}-1_all.ipk
\`\`\`

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
- **Backend**: Shell-based CGI script (\`/www/cgi-bin/enhanced-dhcp-api\`)
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
- \`/etc/config/enhanced_dhcp\` - Main configuration
- \`/etc/init.d/enhanced_dhcp\` - Init script

## Compatibility
- OpenWrt 19.07+
- All architectures (universal package)
- No LuCI version dependencies

## Build Information
- Version: ${VERSION}
- Build Date: $(date)
- Package Size: $(du -h "$OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}-1_all.ipk" | cut -f1)
EOF

    log_success "Documentation generated"
}

# Generate installation test script
generate_test_script() {
    log_info "Generating installation test script..."
    
    cat > "$OUTPUT_DIR/test-install-v2.sh" << 'EOF'
#!/bin/bash

# Enhanced DHCP Manager v2.0 Installation Test Script

set -e

echo "Testing Enhanced DHCP Manager v2.0 Installation..."
echo "================================================="

# Test 1: Check package installation
echo "1. Checking package installation..."
if opkg list-installed | grep -q "luci-app-enhanced-dhcp-v2"; then
    echo "   ✅ Package is installed"
else
    echo "   ❌ Package is not installed"
    exit 1
fi

# Test 2: Check web files
echo "2. Checking web interface files..."
required_files=(
    "/www/enhanced-dhcp/index.html"
    "/www/enhanced-dhcp/style.css"
    "/www/enhanced-dhcp/script.js"
    "/www/enhanced-dhcp/device-types.json"
    "/www/cgi-bin/enhanced-dhcp-api"
)

for file in "${required_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "   ✅ $file exists"
    else
        echo "   ❌ $file missing"
        exit 1
    fi
done

# Test 3: Check CGI script permissions
echo "3. Checking CGI script permissions..."
if [[ -x "/www/cgi-bin/enhanced-dhcp-api" ]]; then
    echo "   ✅ CGI script is executable"
else
    echo "   ❌ CGI script is not executable"
    exit 1
fi

# Test 4: Check configuration
echo "4. Checking UCI configuration..."
if uci show enhanced_dhcp >/dev/null 2>&1; then
    echo "   ✅ UCI configuration accessible"
else
    echo "   ❌ UCI configuration not accessible"
    exit 1
fi

# Test 5: Check init script
echo "5. Checking init script..."
if /etc/init.d/enhanced_dhcp status >/dev/null 2>&1; then
    echo "   ✅ Init script functional"
else
    echo "   ❌ Init script not functional"
    exit 1
fi

# Test 6: Check API endpoint
echo "6. Testing API endpoint..."
if command -v curl >/dev/null 2>&1; then
    if curl -s "http://localhost/cgi-bin/enhanced-dhcp-api/stats" | grep -q "success"; then
        echo "   ✅ API endpoint responding"
    else
        echo "   ❌ API endpoint not responding"
        exit 1
    fi
else
    echo "   ⚠️  curl not available, skipping API test"
fi

# Test 7: Check web interface accessibility
echo "7. Checking web interface files accessibility..."
web_files=(
    "/www/enhanced-dhcp/index.html"
    "/www/enhanced-dhcp/style.css"
    "/www/enhanced-dhcp/script.js"
)

for file in "${web_files[@]}"; do
    if [[ -r "$file" ]]; then
        echo "   ✅ $file is readable"
    else
        echo "   ❌ $file is not readable"
        exit 1
    fi
done

echo ""
echo "🎉 All tests passed! Enhanced DHCP Manager v2.0 is properly installed."
echo ""
echo "Access the web interface at: http://$(uci get network.lan.ipaddr 2>/dev/null || echo "router-ip")/enhanced-dhcp/"
echo ""
EOF

    chmod +x "$OUTPUT_DIR/test-install-v2.sh"
    log_success "Installation test script generated"
}

# Main build process
main() {
    log_info "Starting Enhanced DHCP Manager v2.0 build process..."
    echo "=========================================================="
    
    # Validate environment
    if [[ ! -d "$SCRIPT_DIR/$PROJECT_NAME" ]]; then
        log_error "Source directory not found: $SCRIPT_DIR/$PROJECT_NAME"
        exit 1
    fi
    
    # Build steps
    cleanup
    validate_sources
    create_control_file
    create_postinst_script
    create_prerm_script
    create_conffiles
    copy_package_files
    build_ipk
    generate_documentation
    generate_test_script
    
    echo ""
    log_success "Build completed successfully!"
    echo "=========================================================="
    log_info "Output files:"
    ls -la "$OUTPUT_DIR/"
    echo ""
    log_info "To install: opkg install $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}-1_all.ipk"
    log_info "To test: bash $OUTPUT_DIR/test-install-v2.sh"
    log_info "Web interface: http://[router-ip]/enhanced-dhcp/"
}

# Run main function
main "$@"