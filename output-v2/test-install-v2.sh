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
