#!/bin/bash
# Simple Enhanced DHCP IPK Builder
# Uses standard OpenWrt package building process

set -e

echo "🚀 Building Enhanced DHCP IPK Package"
echo "======================================"

# Configuration
PACKAGE_NAME="luci-app-enhanced-dhcp"

# Read version from VERSION file
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION | tr -d '[:space:]')
    echo "📌 Using version: $VERSION"
else
    echo "❌ VERSION file not found! Please create VERSION file with version number"
    exit 1
fi

RELEASE="1"
IPK_FILE="${PACKAGE_NAME}_${VERSION}-${RELEASE}_all.ipk"

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/enhanced-dhcp"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Clean and prepare
echo "📦 Preparing build environment..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR"

# Create control directory
echo "🔧 Creating control files..."
mkdir -p "$BUILD_DIR/CONTROL"

# Create control file
cat > "$BUILD_DIR/CONTROL/control" <<EOF
Package: luci-app-enhanced-dhcp
Version: ${VERSION}-${RELEASE}
Description: Enhanced DHCP Options Management for OpenWrt
 Provides a web interface to manage DHCP option tags
 and assign them to devices easily.
Section: luci
Category: LuCI
Priority: optional
Maintainer: Enhanced DHCP Team
Architecture: all
Installed-Size: 512
Depends: luci-base, uci, luci-compat
License: MIT
EOF

# Create postinst script
cat > "$BUILD_DIR/CONTROL/postinst" <<'EOF'
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	echo "Setting up Enhanced DHCP..."
	
	# Initialize configuration if not exists
	if ! uci -q get enhanced_dhcp.global >/dev/null 2>&1; then
		uci -q batch <<-EOT
			set enhanced_dhcp.global=global
			set enhanced_dhcp.global.initialized='1'
			set enhanced_dhcp.global.version='${VERSION}'
			commit enhanced_dhcp
		EOT
	fi
	
	# Setup directories
	mkdir -p /var/log
	mkdir -p /usr/share/dhcp_manager
	
	# Restart services
	/etc/init.d/enhanced_dhcp enable 2>/dev/null || true
	/etc/init.d/enhanced_dhcp start 2>/dev/null || true
	/etc/init.d/rpcd restart 2>/dev/null || true
	
	echo "Enhanced DHCP installed successfully!"
	echo "Access via: Network -> Enhanced DHCP"
fi
exit 0
EOF

# Create prerm script
cat > "$BUILD_DIR/CONTROL/prerm" <<'EOF'
#!/bin/sh
if [ -z "${IPKG_INSTROOT}" ]; then
	echo "Removing Enhanced DHCP..."
	/etc/init.d/enhanced_dhcp stop 2>/dev/null || true
	/etc/init.d/enhanced_dhcp disable 2>/dev/null || true
	# Create backup
	mkdir -p /tmp/enhanced_dhcp_backup
	cp /etc/config/enhanced_dhcp /tmp/enhanced_dhcp_backup/ 2>/dev/null || true
fi
exit 0
EOF

# Set permissions
chmod 755 "$BUILD_DIR/CONTROL/postinst"
chmod 755 "$BUILD_DIR/CONTROL/prerm"

# Copy files to build directory
echo "📁 Copying source files..."
mkdir -p "$BUILD_DIR/data"
cp -r "$SRC_DIR/files/"* "$BUILD_DIR/data/"

# Ensure ACL permissions are included
echo "🔐 Adding ACL permissions..."
mkdir -p "$BUILD_DIR/data/usr/share/rpcd/acl.d"
if [ -f "$SRC_DIR/files/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp.json" ]; then
    cp "$SRC_DIR/files/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp.json" "$BUILD_DIR/data/usr/share/rpcd/acl.d/"
    echo "✅ ACL permissions added"
else
    echo "⚠️  ACL file not found, creating default"
    cat > "$BUILD_DIR/data/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp.json" <<'ACLEOF'
{
	"luci-app-enhanced-dhcp": {
		"description": "Grant access to Enhanced DHCP",
		"read": {
			"uci": [ "enhanced_dhcp", "dhcp" ]
		},
		"write": {
			"uci": [ "enhanced_dhcp", "dhcp" ]
		}
	}
}
ACLEOF
fi

# Set correct permissions
echo "🔐 Setting file permissions..."
find "$BUILD_DIR/data" -type d -exec chmod 755 {} \;
find "$BUILD_DIR/data" -name "*.lua" -exec chmod 644 {} \;
find "$BUILD_DIR/data" -name "*.htm" -exec chmod 644 {} \;
find "$BUILD_DIR/data" -name "*.json" -exec chmod 644 {} \;
chmod 644 "$BUILD_DIR/data/etc/config/enhanced_dhcp"
chmod 755 "$BUILD_DIR/data/etc/init.d/enhanced_dhcp"

# Build IPK using correct OpenWrt format (gzipped tar)
echo "🏗️  Building IPK package..."
cd "$BUILD_DIR"

# Create debian-binary (exact OpenWrt format with newline)
echo "2.0" > debian-binary

# Create control.tar.gz (standard OpenWrt compression)
cd CONTROL && tar --owner=0 --group=0 -czf ../control.tar.gz . && cd ..

# Create data.tar.gz (standard OpenWrt compression)  
cd data && tar --owner=0 --group=0 -czf ../data.tar.gz . && cd ..

# Create IPK using tar + gzip (correct OpenWrt format)
# OpenWrt IPK is actually a gzipped tar archive, not ar archive
tar --owner=0 --group=0 -cf "$IPK_FILE.tar" debian-binary control.tar.gz data.tar.gz
gzip "$IPK_FILE.tar"
mv "$IPK_FILE.tar.gz" "$IPK_FILE"

# Move to output
mv "$IPK_FILE" "$OUTPUT_DIR/"

echo ""
echo "✅ Build completed successfully!"
echo "📦 Package: $OUTPUT_DIR/$IPK_FILE"
echo "📏 Size: $(du -h "$OUTPUT_DIR/$IPK_FILE" | cut -f1)"

# Test the package
echo ""
echo "🔍 Verifying package structure..."
cd "$OUTPUT_DIR"
echo "Package format: gzipped tar archive"
zcat "$IPK_FILE" | tar -tf -

echo ""
echo "🎉 Ready for installation!"
echo "Install command: opkg install $IPK_FILE"