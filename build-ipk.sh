#!/bin/bash

# Enhanced DHCP IPK Build Script
# This script builds the Enhanced DHCP package for OpenWrt

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/enhanced-dhcp"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"

PACKAGE_NAME="enhanced-dhcp"
PACKAGE_VERSION="1.0.0"
PACKAGE_RELEASE="1"
PACKAGE_ARCH="all"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log_info "Checking dependencies..."
    
    local missing_deps=()
    
    # Check for required tools
    if ! command -v ar >/dev/null 2>&1; then
        missing_deps+=("binutils (ar command)")
    fi
    
    if ! command -v tar >/dev/null 2>&1; then
        missing_deps+=("tar")
    fi
    
    if ! command -v gzip >/dev/null 2>&1; then
        missing_deps+=("gzip")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        echo "On Ubuntu/Debian: sudo apt-get install binutils tar gzip"
        echo "On macOS: brew install binutils gnu-tar gzip"
        exit 1
    fi
    
    log_success "All dependencies found"
}

# Validate source files
validate_source() {
    log_info "Validating source files..."
    
    local required_files=(
        "$PROJECT_DIR/Makefile"
        "$PROJECT_DIR/CONTROL/control"
        "$PROJECT_DIR/CONTROL/postinst"
        "$PROJECT_DIR/CONTROL/prerm"
        "$PROJECT_DIR/files/usr/lib/lua/luci/controller/dhcp_manager/main.lua"
        "$PROJECT_DIR/files/usr/lib/lua/luci/model/cbi/dhcp_manager/tags.lua"
        "$PROJECT_DIR/files/usr/lib/lua/luci/model/cbi/dhcp_manager/devices.lua"
        "$PROJECT_DIR/files/etc/config/enhanced_dhcp"
        "$PROJECT_DIR/files/etc/init.d/enhanced_dhcp"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -ne 0 ]; then
        log_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        exit 1
    fi
    
    log_success "All required files found"
}

# Clean previous builds
clean_build() {
    log_info "Cleaning previous builds..."
    
    rm -rf "$BUILD_DIR"
    rm -rf "$OUTPUT_DIR"
    
    log_success "Build directories cleaned"
}

# Prepare build directory
prepare_build() {
    log_info "Preparing build directory..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Copy project files to build directory
    cp -r "$PROJECT_DIR"/* "$BUILD_DIR/"
    
    log_success "Build directory prepared"
}

# Validate Lua syntax
validate_lua_syntax() {
    log_info "Validating Lua syntax..."
    
    local lua_files=(
        "$BUILD_DIR/files/usr/lib/lua/luci/controller/dhcp_manager/main.lua"
        "$BUILD_DIR/files/usr/lib/lua/luci/model/cbi/dhcp_manager/tags.lua"
        "$BUILD_DIR/files/usr/lib/lua/luci/model/cbi/dhcp_manager/devices.lua"
    )
    
    for lua_file in "${lua_files[@]}"; do
        if command -v lua >/dev/null 2>&1; then
            if ! lua -c "$lua_file" >/dev/null 2>&1; then
                log_error "Lua syntax error in: $lua_file"
                exit 1
            fi
        else
            log_warn "Lua not found, skipping syntax validation"
            break
        fi
    done
    
    log_success "Lua syntax validation passed"
}

# Set file permissions
set_permissions() {
    log_info "Setting file permissions..."
    
    # Set executable permissions
    chmod +x "$BUILD_DIR/CONTROL/postinst"
    chmod +x "$BUILD_DIR/CONTROL/prerm"
    chmod +x "$BUILD_DIR/files/etc/init.d/enhanced_dhcp"
    
    # Set file permissions
    chmod 644 "$BUILD_DIR/files/etc/config/enhanced_dhcp"
    chmod 644 "$BUILD_DIR/files/usr/share/dhcp_manager/device_types.json"
    
    # Set directory permissions
    find "$BUILD_DIR/files" -type d -exec chmod 755 {} \;
    find "$BUILD_DIR/files" -name "*.lua" -exec chmod 644 {} \;
    find "$BUILD_DIR/files" -name "*.htm" -exec chmod 644 {} \;
    
    log_success "File permissions set"
}

# Build data.tar.gz
build_data() {
    log_info "Building data.tar.gz..."
    
    cd "$BUILD_DIR"
    
    # Create data archive
    tar --owner=root --group=root -czf data.tar.gz -C files .
    
    log_success "data.tar.gz created"
}

# Build control.tar.gz
build_control() {
    log_info "Building control.tar.gz..."
    
    cd "$BUILD_DIR"
    
    # Create control archive
    tar --owner=root --group=root -czf control.tar.gz -C CONTROL .
    
    log_success "control.tar.gz created"
}

# Create debian-binary
create_debian_binary() {
    log_info "Creating debian-binary..."
    
    cd "$BUILD_DIR"
    
    echo "2.0" > debian-binary
    
    log_success "debian-binary created"
}

# Build final IPK
build_ipk() {
    log_info "Building IPK package..."
    
    cd "$BUILD_DIR"
    
    local ipk_filename="${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}_${PACKAGE_ARCH}.ipk"
    
    # Create IPK using ar
    ar r "$ipk_filename" debian-binary control.tar.gz data.tar.gz
    
    # Move to output directory
    mv "$ipk_filename" "$OUTPUT_DIR/"
    
    log_success "IPK package created: $OUTPUT_DIR/$ipk_filename"
}

# Verify IPK package
verify_ipk() {
    log_info "Verifying IPK package..."
    
    local ipk_filename="${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}_${PACKAGE_ARCH}.ipk"
    local ipk_path="$OUTPUT_DIR/$ipk_filename"
    
    if [ ! -f "$ipk_path" ]; then
        log_error "IPK file not found: $ipk_path"
        exit 1
    fi
    
    # Check file size
    local file_size=$(du -k "$ipk_path" | cut -f1)
    if [ "$file_size" -lt 1 ]; then
        log_error "IPK file is too small, possibly corrupted"
        exit 1
    fi
    
    # Verify IPK structure
    if ! ar t "$ipk_path" | grep -q "debian-binary"; then
        log_error "IPK missing debian-binary"
        exit 1
    fi
    
    if ! ar t "$ipk_path" | grep -q "control.tar.gz"; then
        log_error "IPK missing control.tar.gz"
        exit 1
    fi
    
    if ! ar t "$ipk_path" | grep -q "data.tar.gz"; then
        log_error "IPK missing data.tar.gz"
        exit 1
    fi
    
    log_success "IPK package verification passed"
    log_info "Package size: ${file_size}KB"
}

# Generate installation instructions
generate_instructions() {
    local ipk_filename="${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}_${PACKAGE_ARCH}.ipk"
    
    cat > "$OUTPUT_DIR/INSTALL.txt" <<EOF
Enhanced DHCP Installation Instructions
======================================

Package: $ipk_filename
Built on: $(date)

Installation:
1. Copy the IPK file to your OpenWrt router:
   scp $ipk_filename root@192.168.1.1:/tmp/

2. Install the package on OpenWrt:
   opkg install /tmp/$ipk_filename

3. Access the web interface:
   - Go to http://192.168.1.1/cgi-bin/luci
   - Navigate to Network -> Enhanced DHCP

Removal:
opkg remove enhanced-dhcp

Features:
- Create and manage DHCP option templates
- Assign different gateway and DNS settings per device
- Web-based device management interface
- Auto-discovery of network devices
- Configuration backup and restore

Requirements:
- OpenWrt with LuCI
- dnsmasq (usually pre-installed)

For support, please visit: https://github.com/enhanced-dhcp/enhanced-dhcp

EOF
    
    log_success "Installation instructions created: $OUTPUT_DIR/INSTALL.txt"
}

# Main build function
main() {
    echo "Enhanced DHCP IPK Builder"
    echo "========================="
    echo ""
    
    check_dependencies
    validate_source
    clean_build
    prepare_build
    validate_lua_syntax
    set_permissions
    build_data
    build_control
    create_debian_binary
    build_ipk
    verify_ipk
    generate_instructions
    
    echo ""
    log_success "Build completed successfully!"
    echo ""
    echo "Output files:"
    ls -la "$OUTPUT_DIR/"
    echo ""
    echo "Installation command:"
    echo "  opkg install $(basename $OUTPUT_DIR/*.ipk)"
}

# Handle command line arguments
case "${1:-}" in
    clean)
        clean_build
        log_success "Clean completed"
        ;;
    verify)
        verify_ipk
        ;;
    help|--help|-h)
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (none)    Build the IPK package"
        echo "  clean     Clean build directories"
        echo "  verify    Verify existing IPK package"
        echo "  help      Show this help message"
        ;;
    *)
        main
        ;;
esac