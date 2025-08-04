#!/bin/bash

# Enhanced DHCP Manager v2.0 - Data Debug Script
# Compare actual router data with API responses

echo "🔍 Enhanced DHCP Data Debugging Script"
echo "======================================="

# Router IP
ROUTER="192.168.10.2"

echo ""
echo "📋 1. ACTUAL ROUTER DATA:"
echo "========================"

echo ""
echo "📂 DHCP Leases File (/var/dhcp.leases):"
ssh root@$ROUTER 'wc -l /var/dhcp.leases && cat /var/dhcp.leases' || echo "   (empty or not found)"

echo ""
echo "🏠 Static DHCP Hosts (UCI):"
ssh root@$ROUTER 'uci show dhcp | grep -E "host\[.*\]\..*=" | wc -l && echo "--- Host Details ---" && uci show dhcp | grep -E "host\[.*\]\..*="'

echo ""
echo "🏷️  DHCP Tags (UCI):"
ssh root@$ROUTER 'uci show dhcp | grep -E "\..*=tag$" | wc -l && echo "--- Tag Details ---" && uci show dhcp | grep -E "\..*=tag$"'

echo ""
echo "🌐 ARP Table (/proc/net/arp):"
ssh root@$ROUTER 'tail -n +2 /proc/net/arp | wc -l && echo "--- ARP Details ---" && tail -n +2 /proc/net/arp'

echo ""
echo "📊 2. API RESPONSES:"
echo "==================="

echo ""
echo "🔗 API Stats:"
ssh root@$ROUTER 'curl -s http://localhost/cgi-bin/enhanced-dhcp-api/stats'

echo ""
echo ""
echo "💻 API Devices:"
ssh root@$ROUTER 'curl -s http://localhost/cgi-bin/enhanced-dhcp-api/devices'

echo ""
echo ""
echo "🏷️  API Tags:"
ssh root@$ROUTER 'curl -s http://localhost/cgi-bin/enhanced-dhcp-api/tags'

echo ""
echo ""
echo "🔗 API Leases:"
ssh root@$ROUTER 'curl -s http://localhost/cgi-bin/enhanced-dhcp-api/leases'

echo ""
echo ""
echo "🌐 API ARP:"
ssh root@$ROUTER 'curl -s http://localhost/cgi-bin/enhanced-dhcp-api/arp'

echo ""
echo ""
echo "🧪 3. MANUAL API TESTING:"
echo "========================"

echo ""
echo "🔧 Testing UCI commands manually:"
ssh root@$ROUTER '
echo "Test 1: uci foreach dhcp host"
uci foreach dhcp host "echo Found host: \$1"

echo ""
echo "Test 2: uci foreach dhcp tag"  
uci foreach dhcp tag "echo Found tag: \$1"

echo ""
echo "Test 3: Reading DHCP leases"
if [ -f /var/dhcp.leases ]; then
    echo "DHCP leases file exists, size: $(wc -c < /var/dhcp.leases) bytes"
    if [ -s /var/dhcp.leases ]; then
        echo "File has content:"
        cat /var/dhcp.leases
    else
        echo "File is empty"
    fi
else
    echo "DHCP leases file does not exist"
fi

echo ""
echo "Test 4: ARP parsing"
tail -n +2 /proc/net/arp | while read line; do
    set -- $line
    echo "ARP: IP=$1, MAC=$4, Device=$6"
done | head -3
'

echo ""
echo "🐛 4. CGI SCRIPT DEBUGGING:"
echo "=========================="

echo ""
echo "CGI Script permissions and location:"
ssh root@$ROUTER 'ls -la /www/cgi-bin/enhanced-dhcp-api'

echo ""
echo "CGI Script environment test:"
ssh root@$ROUTER '
export REQUEST_METHOD=GET
export PATH_INFO=/devices
export QUERY_STRING=""
echo "Testing CGI script directly..."
/www/cgi-bin/enhanced-dhcp-api
'

echo ""
echo "========================================="
echo "🔍 ANALYSIS COMPLETE"
echo "Compare the actual data (section 1) with API responses (section 2)"
echo "If API shows empty data but actual data exists, the parsing is broken"
echo "========================================="