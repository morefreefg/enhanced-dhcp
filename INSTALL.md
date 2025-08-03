# Enhanced DHCP Installation Instructions

## 📦 Package Information
- **Package**: enhanced-dhcp_1.0.0-1_all.ipk
- **Size**: 16KB
- **Architecture**: all (compatible with all OpenWrt platforms)
- **Dependencies**: luci-base, dnsmasq, uci

## 🚀 Installation Steps

### 1. Transfer IPK to OpenWrt Router
```bash
scp enhanced-dhcp_1.0.0-1_all.ipk root@192.168.1.1:/tmp/
```

### 2. Install Package
SSH into your OpenWrt router and run:
```bash
opkg install /tmp/enhanced-dhcp_1.0.0-1_all.ipk
```

### 3. Access Web Interface
1. Open your web browser
2. Navigate to your router's LuCI interface (usually http://192.168.1.1)
3. Go to **Network** → **Enhanced DHCP**

## ⚙️ Configuration

### Initial Setup
The package automatically:
- Creates default configuration files
- Enables the enhanced_dhcp service
- Integrates with existing dnsmasq configuration
- Sets up logging and backup systems

### Creating DHCP Tags
1. Go to **Network** → **Enhanced DHCP** → **DHCP Tags**
2. Click **Add** to create a new tag
3. Configure:
   - **Tag Name**: Unique identifier (3-32 characters)
   - **Gateway**: Router IP for this network segment
   - **DNS Servers**: Comma-separated DNS server IPs
   - **Description**: Optional description

### Managing Devices
1. Go to **Network** → **Enhanced DHCP** → **Device Management**
2. Use **Discover Devices** to automatically find network devices
3. Assign tags to devices using the dropdown menus
4. Use **Quick Assignment** for bulk operations

## 🔧 Service Management

### Command Line Interface
```bash
# Check service status
/etc/init.d/enhanced_dhcp status

# Start/stop service
/etc/init.d/enhanced_dhcp start
/etc/init.d/enhanced_dhcp stop

# Reload configuration
/etc/init.d/enhanced_dhcp reload

# Health check
/etc/init.d/enhanced_dhcp health

# Backup configuration
/etc/init.d/enhanced_dhcp backup
```

### Configuration Files
- Main config: `/etc/config/enhanced_dhcp`
- DHCP config: `/etc/config/dhcp` (shared with system)
- Log file: `/var/log/enhanced_dhcp.log`
- Backups: `/etc/config/enhanced_dhcp_backups/`

## 📊 Features Overview

### Web Interface
- **Overview Dashboard**: System statistics and current leases
- **DHCP Tags**: Create and manage option templates
- **Device Management**: Assign tags to network devices
- **Auto-Discovery**: Automatically find network devices

### DHCP Options Supported
- **Option 3**: Gateway/Router IP
- **Option 6**: DNS Servers
- **Static IP**: Optional static IP assignment

### Advanced Features
- Configuration backup and restore
- Audit logging of all changes
- Device type detection
- Bulk tag assignment
- Real-time device discovery

## 🛠️ Troubleshooting

### Common Issues

**Web interface not appearing**
- Ensure LuCI is installed: `opkg list-installed | grep luci`
- Clear browser cache and reload

**DHCP tags not working**
- Check dnsmasq is running: `/etc/init.d/dnsmasq status`
- Verify configuration: `uci show dhcp`
- Restart dnsmasq: `/etc/init.d/dnsmasq restart`

**Devices not discovered**
- Check network connectivity
- Verify ARP table: `cat /proc/net/arp`
- Enable device discovery in settings

### Log Analysis
```bash
# View recent logs
tail -f /var/log/enhanced_dhcp.log

# Check system logs
logread | grep enhanced_dhcp

# View DHCP leases
cat /var/dhcp.leases
```

## 🔄 Uninstallation

### Remove Package
```bash
opkg remove enhanced-dhcp
```

### Cleanup (Optional)
```bash
# Remove configuration backups
rm -rf /etc/config/enhanced_dhcp_backups

# Remove logs
rm -f /var/log/enhanced_dhcp.log
```

**Note**: The system DHCP configuration (`/etc/config/dhcp`) is preserved during uninstallation.

## 📚 Additional Resources

### Configuration Examples

**Office Network Tag**:
```
config tag 'office'
    list dhcp_option '3,192.168.1.1'
    list dhcp_option '6,8.8.8.8,8.8.4.4'
    option description 'Office network with Google DNS'
```

**Guest Network Tag**:
```
config tag 'guest'
    list dhcp_option '3,192.168.100.1'
    list dhcp_option '6,1.1.1.1,1.0.0.1'
    option description 'Guest network with Cloudflare DNS'
```

**Device Assignment**:
```
config host
    option name 'office-laptop'
    option mac '00:11:22:33:44:55'
    option ip '192.168.1.100'
    option tag 'office'
```

### Support
- Documentation: See README.md
- Issues: GitHub repository
- Community: OpenWrt forums

## ✅ Verification

After installation, verify the system is working:

1. **Check service status**:
   ```bash
   /etc/init.d/enhanced_dhcp status
   ```

2. **Access web interface**:
   - Navigate to Network → Enhanced DHCP
   - Verify all three tabs are accessible

3. **Test DHCP functionality**:
   - Create a test tag
   - Assign it to a device
   - Verify the device receives the correct settings

## 🎯 Next Steps

1. **Create your DHCP tags** based on your network requirements
2. **Discover and assign devices** using the web interface  
3. **Monitor the system** through the overview dashboard
4. **Set up backups** to preserve your configuration

The Enhanced DHCP system is now ready to manage your network's DHCP options efficiently!