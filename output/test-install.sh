#!/bin/sh
# Enhanced DHCP Installation Test Script
# Tests installation on OpenWrt device

echo "Enhanced DHCP Installation Test"
echo "==============================="

IPK_FILE="luci-app-enhanced-dhcp_1.0.0-1_all.ipk"

if [ ! -f "$IPK_FILE" ]; then
    echo "❌ IPK file not found: $IPK_FILE"
    exit 1
fi

echo "📦 Testing IPK structure..."
ar t "$IPK_FILE" | while read file; do
    echo "  ✓ $file"
done

echo ""
echo "🔍 Testing installation..."

# Update package lists
echo "Updating package lists..."
opkg update

# Install package
echo "Installing Enhanced DHCP..."
opkg install "./$IPK_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Installation successful!"
    
    # Test service
    echo ""
    echo "🔧 Testing service..."
    /etc/init.d/enhanced_dhcp status
    
    # Test UCI config
    echo ""
    echo "📋 Testing UCI configuration..."
    uci show enhanced_dhcp
    
    echo ""
    echo "🌐 Testing LuCI integration..."
    echo "Please check: Network -> Enhanced DHCP in LuCI web interface"
    
else
    echo "❌ Installation failed!"
    echo "Check logs: logread | grep -i enhanced"
    exit 1
fi
