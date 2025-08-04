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
endef

define Package/luci-app-enhanced-dhcp-v2/postinst
#!/bin/sh
# Post-installation script

# Check if we're in a real system
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Configuring Enhanced DHCP Manager v2.0..."
	
	# Enable and start the service
	/etc/init.d/enhanced_dhcp enable
	/etc/init.d/enhanced_dhcp start
	
	# Set up web server configuration if needed
	if [ -f /etc/config/uhttpd ]; then
		# Ensure CGI support is enabled
		uci -q get uhttpd.main.cgi_prefix >/dev/null || {
			uci set uhttpd.main.cgi_prefix='/cgi-bin'
			uci commit uhttpd
			/etc/init.d/uhttpd restart
		}
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