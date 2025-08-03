#!/bin/bash
# Enhanced DHCP Manual Installation Script
# Works around IPK format issues by installing files directly

set -e

TARGET_IP="192.168.10.2"
TARGET_USER="root"
PACKAGE_NAME="luci-app-enhanced-dhcp"

echo "🚀 Enhanced DHCP Manual Installation"
echo "===================================="

# Step 1: Build the package
echo "📦 Building package..."
if ! ./build.sh; then
    echo "❌ Build failed"
    exit 1
fi

echo "📤 Deploying to $TARGET_IP..."

# Step 2: Copy source files directly
echo "📁 Copying files directly..."
scp -r enhanced-dhcp/files/* root@$TARGET_IP:/

# Step 3: Set proper permissions
echo "🔐 Setting permissions..."
ssh root@$TARGET_IP '
    chmod 755 /etc/init.d/enhanced_dhcp
    chmod 644 /etc/config/enhanced_dhcp
    chmod 644 /usr/lib/lua/luci/controller/enhanced_dhcp.lua
    chmod 644 /usr/lib/lua/luci/model/cbi/*.lua
    chmod 644 /usr/lib/lua/luci/view/*.htm
'

# Step 4: Initialize configuration
echo "⚙️  Initializing configuration..."
ssh root@$TARGET_IP 'uci set enhanced_dhcp.global=global; uci set enhanced_dhcp.global.initialized=1; uci set enhanced_dhcp.global.version=1.0.0; uci commit enhanced_dhcp'
ssh root@$TARGET_IP 'mkdir -p /var/log; mkdir -p /usr/share/dhcp_manager'
ssh root@$TARGET_IP '/etc/init.d/enhanced_dhcp enable; /etc/init.d/enhanced_dhcp start; /etc/init.d/rpcd restart'

echo ""
echo "✅ Installation completed successfully!"
echo ""
echo "🌐 Access via: http://$TARGET_IP/cgi-bin/luci"
echo "📍 Navigate to: Network → Enhanced DHCP"
echo ""
echo "Available pages:"
echo "  • Overview: Network → Enhanced DHCP → Overview"
echo "  • Devices:  Network → Enhanced DHCP → Devices"
echo "  • Tags:     Network → Enhanced DHCP → Tags"