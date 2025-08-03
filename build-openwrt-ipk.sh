#!/bin/bash

# OpenWrt compatible IPK build script
# Creates IPK packages optimized for OpenWrt installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/enhanced-dhcp"
BUILD_DIR="$SCRIPT_DIR/build-openwrt"
OUTPUT_DIR="$SCRIPT_DIR/output"

PACKAGE_NAME="enhanced-dhcp"
PACKAGE_VERSION="1.0.0"
PACKAGE_RELEASE="1"
PACKAGE_ARCH="all"

echo "Building OpenWrt-compatible IPK package..."

# Clean and prepare
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# Copy source files
cp -r "$PROJECT_DIR"/* "$BUILD_DIR/"

# Create debian-binary file
echo "2.0" > "$BUILD_DIR/debian-binary"

# Fix control file for OpenWrt compatibility
cat > "$BUILD_DIR/CONTROL/control" <<EOF
Package: enhanced-dhcp
Version: 1.0.0-1
Description: Enhanced DHCP Options Management for OpenWrt
Section: net
Priority: optional
Maintainer: Enhanced DHCP Team
Architecture: all
Installed-Size: 256
Depends: luci-base, dnsmasq, uci
EOF

# Set proper permissions
chmod +x "$BUILD_DIR/CONTROL/postinst"
chmod +x "$BUILD_DIR/CONTROL/prerm"
chmod +x "$BUILD_DIR/files/etc/init.d/enhanced_dhcp"
chmod 644 "$BUILD_DIR/files/etc/config/enhanced_dhcp"

# Create data.tar.gz (OpenWrt compatible)
cd "$BUILD_DIR"
tar --numeric-owner --owner=0 --group=0 -czf data.tar.gz -C files .

# Create control.tar.gz (OpenWrt compatible)
tar --numeric-owner --owner=0 --group=0 -czf control.tar.gz -C CONTROL .

# Create IPK using ar (compatible with OpenWrt's opkg)
IPK_FILE="${PACKAGE_NAME}_${PACKAGE_VERSION}-${PACKAGE_RELEASE}_${PACKAGE_ARCH}.ipk"

# Use specific ar format for better compatibility
ar -r "$IPK_FILE" debian-binary control.tar.gz data.tar.gz

# Move to output directory
mv "$IPK_FILE" "$OUTPUT_DIR/"

# Verify the package
echo ""
echo "Package created: $OUTPUT_DIR/$IPK_FILE"
echo "Size: $(du -h "$OUTPUT_DIR/$IPK_FILE" | cut -f1)"

# Validate package structure
echo "Package contents:"
ar t "$OUTPUT_DIR/$IPK_FILE"

echo ""
echo "Installation commands:"
echo "1. scp $OUTPUT_DIR/$IPK_FILE root@192.168.1.1:/tmp/"
echo "2. opkg install /tmp/$IPK_FILE"

echo ""
echo "Build completed successfully!"