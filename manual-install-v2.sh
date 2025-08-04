#!/bin/bash

# Enhanced DHCP Manager v2.0 - Manual Installation Script
# Use this if the IPK installation fails

echo "🔧 Enhanced DHCP Manager v2.0 - Manual Installation"
echo "==================================================="

# Check if we're running on OpenWrt
if [ ! -f /etc/openwrt_release ]; then
    echo "❌ This script must be run on an OpenWrt router"
    exit 1
fi

echo "📁 Creating directory structure..."

# Create directories
mkdir -p /www/enhanced-dhcp
mkdir -p /www/cgi-bin
mkdir -p /etc/config

# Extract and install files from the current directory
if [ -f "enhanced-dhcp-v2.tar.gz" ]; then
    echo "📦 Extracting files from enhanced-dhcp-v2.tar.gz..."
    tar -xzf enhanced-dhcp-v2.tar.gz
elif [ -d "enhanced-dhcp-v2" ]; then
    echo "📁 Using local enhanced-dhcp-v2 directory..."
else
    echo "❌ No enhanced-dhcp-v2.tar.gz or directory found"
    echo "Please ensure the source files are in the current directory"
    exit 1
fi

echo "📋 Installing files..."

# Copy configuration
if [ -f "enhanced-dhcp-v2/files/etc/config/enhanced_dhcp" ]; then
    cp "enhanced-dhcp-v2/files/etc/config/enhanced_dhcp" /etc/config/
    echo "   ✅ Configuration installed"
else
    echo "   ❌ Configuration file not found"
fi

# Copy init script
if [ -f "enhanced-dhcp-v2/files/etc/init.d/enhanced_dhcp" ]; then
    cp "enhanced-dhcp-v2/files/etc/init.d/enhanced_dhcp" /etc/init.d/
    chmod +x /etc/init.d/enhanced_dhcp
    echo "   ✅ Init script installed"
else
    echo "   ❌ Init script not found"
fi

# Copy web files
web_files=(
    "index.html"
    "style.css"
    "script.js"
    "device-types.json"
)

for file in "${web_files[@]}"; do
    if [ -f "enhanced-dhcp-v2/files/www/enhanced-dhcp/$file" ]; then
        cp "enhanced-dhcp-v2/files/www/enhanced-dhcp/$file" /www/enhanced-dhcp/
        chmod 644 "/www/enhanced-dhcp/$file"
        echo "   ✅ $file installed"
    else
        echo "   ❌ $file not found"
    fi
done

# Copy CGI script
if [ -f "enhanced-dhcp-v2/files/www/cgi-bin/enhanced-dhcp-api" ]; then
    cp "enhanced-dhcp-v2/files/www/cgi-bin/enhanced-dhcp-api" /www/cgi-bin/
    chmod +x /www/cgi-bin/enhanced-dhcp-api
    echo "   ✅ CGI API installed"
else
    echo "   ❌ CGI API script not found"
fi

echo "🔧 Setting up permissions..."

# Set proper ownership and permissions
chown -R root:root /www/enhanced-dhcp
chown root:root /www/cgi-bin/enhanced-dhcp-api
chmod 755 /www/enhanced-dhcp
chmod 644 /www/enhanced-dhcp/*
chmod 755 /www/cgi-bin/enhanced-dhcp-api

echo "🌐 Configuring web server..."

# Ensure CGI support is enabled
if ! uci -q get uhttpd.main.cgi_prefix >/dev/null 2>&1; then
    uci set uhttpd.main.cgi_prefix='/cgi-bin'
    uci commit uhttpd
    echo "   ✅ CGI support enabled"
fi

# Restart web server
/etc/init.d/uhttpd restart
echo "   ✅ Web server restarted"

echo "🚀 Starting Enhanced DHCP service..."

# Enable and start service
/etc/init.d/enhanced_dhcp enable
/etc/init.d/enhanced_dhcp start

echo "✅ Verifying installation..."

# Check files
missing_files=0
check_files=(
    "/www/enhanced-dhcp/index.html"
    "/www/enhanced-dhcp/style.css"
    "/www/enhanced-dhcp/script.js"
    "/www/enhanced-dhcp/device-types.json"
    "/www/cgi-bin/enhanced-dhcp-api"
    "/etc/config/enhanced_dhcp"
    "/etc/init.d/enhanced_dhcp"
)

for file in "${check_files[@]}"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file MISSING"
        missing_files=$((missing_files + 1))
    fi
done

# Test CGI script
if [ -x "/www/cgi-bin/enhanced-dhcp-api" ]; then
    echo "   ✅ CGI script is executable"
else
    echo "   ❌ CGI script is not executable"
    missing_files=$((missing_files + 1))
fi

echo ""
if [ $missing_files -eq 0 ]; then
    echo "🎉 Manual installation completed successfully!"
    echo ""
    router_ip=$(uci get network.lan.ipaddr 2>/dev/null || echo "router-ip")
    echo "📱 Access the interface at: http://$router_ip/enhanced-dhcp/"
    echo "🔧 API endpoint: http://$router_ip/cgi-bin/enhanced-dhcp-api"
    echo ""
    echo "🔍 To test the API:"
    echo "   curl http://$router_ip/cgi-bin/enhanced-dhcp-api/stats"
else
    echo "❌ Installation completed with $missing_files missing files"
    echo "Please check the source files and try again"
fi

# Cleanup
rm -rf enhanced-dhcp-v2 2>/dev/null || true