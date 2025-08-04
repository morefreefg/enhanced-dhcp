#!/bin/bash

# Enhanced DHCP Manager v2.0 - Installation Fix Script
# Fixes file permissions and directory access issues

echo "🔧 Enhanced DHCP Manager v2.0 - Installation Fix"
echo "================================================="

# Check if we're running on the target device
if [ ! -f /etc/openwrt_release ]; then
    echo "❌ This script should be run on the OpenWrt router"
    exit 1
fi

echo "📂 Checking and fixing file permissions..."

# Ensure directories exist with proper permissions
mkdir -p /www/enhanced-dhcp
mkdir -p /www/cgi-bin
chown -R root:root /www/enhanced-dhcp
chown root:root /www/cgi-bin/enhanced-dhcp-api

# Set proper permissions for web files
chmod 755 /www/enhanced-dhcp
chmod 644 /www/enhanced-dhcp/*.html 2>/dev/null || true
chmod 644 /www/enhanced-dhcp/*.css 2>/dev/null || true  
chmod 644 /www/enhanced-dhcp/*.js 2>/dev/null || true
chmod 644 /www/enhanced-dhcp/*.json 2>/dev/null || true

# Set CGI script permissions
chmod 755 /www/cgi-bin/enhanced-dhcp-api

# Check and fix uhttpd configuration
echo "🌐 Checking web server configuration..."

# Ensure CGI is enabled in uhttpd
if ! uci get uhttpd.main.cgi_prefix >/dev/null 2>&1; then
    echo "   Setting up CGI support..."
    uci set uhttpd.main.cgi_prefix='/cgi-bin'
    uci commit uhttpd
fi

# Restart uhttpd to apply changes
/etc/init.d/uhttpd restart

# Verify file existence and permissions
echo "✅ Verifying installation..."

files_to_check=(
    "/www/enhanced-dhcp/index.html"
    "/www/enhanced-dhcp/style.css"
    "/www/enhanced-dhcp/script.js"
    "/www/enhanced-dhcp/device-types.json"
    "/www/cgi-bin/enhanced-dhcp-api"
)

all_good=true
for file in "${files_to_check[@]}"; do
    if [[ -f "$file" ]]; then
        echo "   ✅ $file exists"
    else
        echo "   ❌ $file missing"
        all_good=false
    fi
done

if [[ "$all_good" == "true" ]]; then
    echo ""
    echo "🎉 Installation fixed successfully!"
    echo ""
    echo "📱 Access the web interface at:"
    router_ip=$(uci get network.lan.ipaddr 2>/dev/null || echo "router-ip")
    echo "   http://$router_ip/enhanced-dhcp/"
    echo ""
    echo "🔧 API endpoint available at:"
    echo "   http://$router_ip/cgi-bin/enhanced-dhcp-api"
    echo ""
else
    echo ""
    echo "❌ Some files are still missing. Please reinstall the package:"
    echo "   opkg remove luci-app-enhanced-dhcp-v2"
    echo "   opkg install luci-app-enhanced-dhcp-v2_2.0.0-1_all.ipk"
fi