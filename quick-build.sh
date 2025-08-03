#!/bin/bash

# Quick build script for Enhanced DHCP IPK
# Simplified version for rapid development and testing

set -e

echo "Enhanced DHCP - Quick Build"
echo "==========================="

PACKAGE_NAME="enhanced-dhcp"
PACKAGE_VERSION="1.0.0"
PACKAGE_ARCH="all"

# Clean and create build directory
rm -rf build output
mkdir -p build output

echo "Copying files..."
cp -r enhanced-dhcp/* build/

echo "Setting permissions..."
chmod +x build/CONTROL/postinst
chmod +x build/CONTROL/prerm
chmod +x build/files/etc/init.d/enhanced_dhcp

cd build

echo "Creating archives..."
# Create data.tar.gz
tar -czf data.tar.gz -C files .

# Create control.tar.gz
tar -czf control.tar.gz -C CONTROL .

# Create debian-binary
echo "2.0" > debian-binary

echo "Building IPK..."
# Create IPK
ar r "${PACKAGE_NAME}_${PACKAGE_VERSION}-1_${PACKAGE_ARCH}.ipk" debian-binary control.tar.gz data.tar.gz

# Move to output
mv "${PACKAGE_NAME}_${PACKAGE_VERSION}-1_${PACKAGE_ARCH}.ipk" ../output/

cd ..

echo ""
echo "Build completed!"
echo "IPK file: output/${PACKAGE_NAME}_${PACKAGE_VERSION}-1_${PACKAGE_ARCH}.ipk"
echo "Size: $(du -h output/*.ipk | cut -f1)"

echo ""
echo "To install on OpenWrt:"
echo "1. scp output/${PACKAGE_NAME}_${PACKAGE_VERSION}-1_${PACKAGE_ARCH}.ipk root@192.168.1.1:/tmp/"
echo "2. opkg install /tmp/${PACKAGE_NAME}_${PACKAGE_VERSION}-1_${PACKAGE_ARCH}.ipk"