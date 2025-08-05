#!/bin/bash

# Enhanced DHCP Manager v2.0 - LuCI Integration Build Script
# Builds a LuCI-integrated IPK package for all OpenWrt platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="enhanced-dhcp"
VERSION="2.0.0"
PACKAGE_NAME="luci-app-enhanced-dhcp"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"

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
        "$SCRIPT_DIR/$PROJECT_NAME/files/etc/config/enhanced_dhcp"
        "$SCRIPT_DIR/$PROJECT_NAME/files/etc/init.d/enhanced_dhcp"
        "$SCRIPT_DIR/$PROJECT_NAME/files/usr/lib/lua/luci/controller/enhanced_dhcp.lua"
        "$SCRIPT_DIR/$PROJECT_NAME/files/usr/lib/lua/luci/view/enhanced_dhcp.htm"
        "$SCRIPT_DIR/$PROJECT_NAME/files/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp.json"
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
Description: Enhanced DHCP Manager v2.0 - LuCI Integration
 A modern DHCP management interface integrated with LuCI admin panel.
 .
 Features:
 - Full LuCI integration in Network section
 - Real-time DHCP lease monitoring  
 - Device auto-discovery and classification
 - DHCP tag management for different network policies
 - Responsive web interface
 - Compatible with all OpenWrt versions
 .
 This version provides comprehensive DHCP management functionality
 through the standard LuCI web interface.
Section: luci
Priority: optional
Maintainer: Enhanced DHCP Team <support@enhanced-dhcp.org>
License: MIT
Architecture: all
Installed-Size: $(du -sb "$SCRIPT_DIR/$PROJECT_NAME/files" | cut -f1)
Depends: uhttpd, uhttpd-mod-ubus, luci-base
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
echo "Access via LuCI web interface: Network → Enhanced DHCP"
echo "Direct URL: http://[router-ip]/cgi-bin/luci/admin/network/enhanced_dhcp"
echo ""
echo "Key improvements in v2.0:"
echo "- Full LuCI integration in Network section"
echo "- Complete device management and tag assignment"
echo "- Modern responsive interface"
echo "- Real-time DHCP monitoring"

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
    
    local package_file="${PACKAGE_NAME}_${VERSION}_all.ipk"
    
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
    
    echo ""
    log_success "Build completed successfully!"
    echo "=========================================================="
    log_info "Output files:"
    ls -la "$OUTPUT_DIR/"
    echo ""
    log_info "To install: opkg install $OUTPUT_DIR/${PACKAGE_NAME}_${VERSION}-1_all.ipk"
    log_info "To test: ./test.sh"
    log_info "LuCI interface: Network → Enhanced DHCP"
}

# Run main function
main "$@"