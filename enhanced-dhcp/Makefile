include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-enhanced-dhcp
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=Enhanced DHCP Team

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-enhanced-dhcp
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Enhanced DHCP Options Management
  DEPENDS:=+luci-base +uci +luci-compat
  MAINTAINER:=Enhanced DHCP Team
  PKGARCH:=all
endef

define Package/luci-app-enhanced-dhcp/description
  Enhanced DHCP Options Management for OpenWrt
  Provides a web interface to manage DHCP option tags
  and assign them to devices easily.
  
  Features:
  - Create and manage DHCP option templates (tags)
  - Assign different gateway and DNS settings per device
  - Web-based device management interface
  - Integration with OpenWrt UCI and dnsmasq
endef

define Package/luci-app-enhanced-dhcp/conffiles
/etc/config/enhanced_dhcp
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-enhanced-dhcp/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/dhcp_manager/*.lua $(1)/usr/lib/lua/luci/controller/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/dhcp_manager/*.lua $(1)/usr/lib/lua/luci/model/cbi/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/dhcp_manager/*.htm $(1)/usr/lib/lua/luci/view/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/enhanced_dhcp $(1)/etc/config/
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/enhanced_dhcp $(1)/etc/init.d/
	
	$(INSTALL_DIR) $(1)/usr/share/dhcp_manager
	$(INSTALL_DATA) ./files/usr/share/dhcp_manager/device_types.json $(1)/usr/share/dhcp_manager/
endef

define Package/luci-app-enhanced-dhcp/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Setting up Enhanced DHCP..."
	
	# Initialize configuration if not exists
	if ! uci -q get enhanced_dhcp.global >/dev/null 2>&1; then
		uci -q batch <<-EOF
			set enhanced_dhcp.global=global
			set enhanced_dhcp.global.initialized='1'
			set enhanced_dhcp.global.version='1.0.0'
			commit enhanced_dhcp
		EOF
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
endef

define Package/luci-app-enhanced-dhcp/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Removing Enhanced DHCP..."
	/etc/init.d/enhanced_dhcp stop 2>/dev/null || true
	/etc/init.d/enhanced_dhcp disable 2>/dev/null || true
	# Create backup
	mkdir -p /tmp/enhanced_dhcp_backup
	cp /etc/config/enhanced_dhcp /tmp/enhanced_dhcp_backup/ 2>/dev/null || true
fi
exit 0
endef

$(eval $(call BuildPackage,luci-app-enhanced-dhcp))