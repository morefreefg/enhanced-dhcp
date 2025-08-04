include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-enhanced-dhcp-v2
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_MAINTAINER:=Enhanced DHCP Team <support@enhanced-dhcp.org>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-enhanced-dhcp-v2
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=Enhanced DHCP Manager v2.0 - HTML Edition
	PKGARCH:=all
	DEPENDS:=+uhttpd +uhttpd-mod-ubus
	MAINTAINER:=Enhanced DHCP Team <support@enhanced-dhcp.org>
endef

define Package/luci-app-enhanced-dhcp-v2/description
	Enhanced DHCP Manager v2.0 - HTML Edition
	
	A modern, LuCI-independent DHCP management interface built with pure HTML/CSS/JS.
	Features:
	- Pure HTML frontend (no LuCI dependencies)
	- Real-time DHCP lease monitoring
	- Device auto-discovery and classification
	- DHCP tag management for different network policies
	- Responsive web interface
	- Compatible with all OpenWrt versions
	
	This version eliminates LuCI compatibility issues by using a standalone
	CGI backend and modern web technologies for the frontend.
endef

define Package/luci-app-enhanced-dhcp-v2/conffiles
/etc/config/enhanced_dhcp
endef

define Build/Compile
	# Nothing to compile - pure shell/HTML/CSS/JS
endef

define Package/luci-app-enhanced-dhcp-v2/install
	# Configuration files
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/enhanced_dhcp $(1)/etc/config/
	
	# Init script
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/enhanced_dhcp $(1)/etc/init.d/
	
	# Web interface files
	$(INSTALL_DIR) $(1)/www/enhanced-dhcp
	$(INSTALL_DATA) ./files/www/enhanced-dhcp/index.html $(1)/www/enhanced-dhcp/
	$(INSTALL_DATA) ./files/www/enhanced-dhcp/style.css $(1)/www/enhanced-dhcp/
	$(INSTALL_DATA) ./files/www/enhanced-dhcp/script.js $(1)/www/enhanced-dhcp/
	$(INSTALL_DATA) ./files/www/enhanced-dhcp/device-types.json $(1)/www/enhanced-dhcp/
	
	# CGI API backend
	$(INSTALL_DIR) $(1)/www/cgi-bin
	$(INSTALL_BIN) ./files/www/cgi-bin/enhanced-dhcp-api $(1)/www/cgi-bin/
	
	# LuCI integration files
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/enhanced_dhcp_v2.lua $(1)/usr/lib/lua/luci/controller/
	
	# LuCI view templates
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/enhanced_dhcp_v2.htm $(1)/usr/lib/lua/luci/view/
	
	# ACL permissions for LuCI
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./files/usr/share/rpcd/acl.d/luci-app-enhanced-dhcp-v2.json $(1)/usr/share/rpcd/acl.d/
endef

define Package/luci-app-enhanced-dhcp-v2/postinst
#!/bin/sh
# Post-installation script

# Check if we're in a real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Configuring Enhanced DHCP Manager v2.0..."
	
	# Ensure directories exist with proper permissions
	mkdir -p /www/enhanced-dhcp
	mkdir -p /www/cgi-bin
	chown -R root:root /www/enhanced-dhcp 2>/dev/null || true
	
	# Set proper file permissions
	chmod 755 /www/enhanced-dhcp
	chmod 644 /www/enhanced-dhcp/*.html 2>/dev/null || true
	chmod 644 /www/enhanced-dhcp/*.css 2>/dev/null || true
	chmod 644 /www/enhanced-dhcp/*.js 2>/dev/null || true
	chmod 644 /www/enhanced-dhcp/*.json 2>/dev/null || true
	chmod 755 /www/cgi-bin/enhanced-dhcp-api 2>/dev/null || true
	
	# Enable and start the service
	/etc/init.d/enhanced_dhcp enable 2>/dev/null || true
	/etc/init.d/enhanced_dhcp start 2>/dev/null || true
	
	# Set up web server configuration if needed
	if [ -f /etc/config/uhttpd ]; then
		# Ensure CGI support is enabled
		if ! uci -q get uhttpd.main.cgi_prefix >/dev/null 2>&1; then
			uci set uhttpd.main.cgi_prefix='/cgi-bin'
			uci commit uhttpd
			/etc/init.d/uhttpd restart 2>/dev/null || true
		fi
	fi
	
	echo "Enhanced DHCP Manager v2.0 installed successfully!"
	echo "Access the web interface at: http://[router-ip]/enhanced-dhcp/"
	echo ""
	echo "Key improvements in v2.0:"
	echo "- No LuCI dependencies (eliminates compatibility issues)"
	echo "- Modern HTML/CSS/JS frontend"
	echo "- Better performance and stability"
	echo "- Compatible with all OpenWrt versions"
fi
exit 0
endef

define Package/luci-app-enhanced-dhcp-v2/prerm
#!/bin/sh
# Pre-removal script

# Check if we're in a real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Stopping Enhanced DHCP Manager v2.0..."
	
	# Stop and disable the service
	/etc/init.d/enhanced_dhcp stop
	/etc/init.d/enhanced_dhcp disable
fi
exit 0
endef

$(eval $(call BuildPackage,luci-app-enhanced-dhcp-v2))