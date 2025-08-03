include $(TOPDIR)/rules.mk

PKG_NAME:=enhanced-dhcp
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/enhanced-dhcp
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=IP Addresses and Names
  TITLE:=Enhanced DHCP Options Management
  DEPENDS:=+luci-base +dnsmasq +uci
  MAINTAINER:=Enhanced DHCP Team
  PKGARCH:=all
endef

define Package/enhanced-dhcp/description
  Enhanced DHCP Options Management for OpenWrt
  Provides a web interface to manage DHCP option tags
  and assign them to devices easily.
  
  Features:
  - Create and manage DHCP option templates (tags)
  - Assign different gateway and DNS settings per device
  - Web-based device management interface
  - Integration with OpenWrt UCI and dnsmasq
endef

define Package/enhanced-dhcp/conffiles
/etc/config/enhanced_dhcp
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/enhanced-dhcp/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller/dhcp_manager
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/controller/dhcp_manager/*.lua $(1)/usr/lib/lua/luci/controller/dhcp_manager/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/dhcp_manager
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/model/cbi/dhcp_manager/*.lua $(1)/usr/lib/lua/luci/model/cbi/dhcp_manager/
	
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/dhcp_manager
	$(INSTALL_DATA) ./files/usr/lib/lua/luci/view/dhcp_manager/*.htm $(1)/usr/lib/lua/luci/view/dhcp_manager/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/etc/config/enhanced_dhcp $(1)/etc/config/
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/enhanced_dhcp $(1)/etc/init.d/
	
	$(INSTALL_DIR) $(1)/usr/share/dhcp_manager
	$(INSTALL_DATA) ./files/usr/share/dhcp_manager/* $(1)/usr/share/dhcp_manager/ 2>/dev/null || true
endef

define Package/enhanced-dhcp/postinst
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Setting up Enhanced DHCP..."
	
	# Initialize configuration if not exists
	if ! uci -q get enhanced_dhcp.@global[0] >/dev/null; then
		uci set enhanced_dhcp.global=global
		uci set enhanced_dhcp.global.initialized='1'
		uci commit enhanced_dhcp
	fi
	
	# Restart services
	/etc/init.d/enhanced_dhcp enable
	/etc/init.d/enhanced_dhcp start
	/etc/init.d/dnsmasq restart
	
	echo "Enhanced DHCP installed successfully!"
	echo "Access via: System -> Enhanced DHCP"
fi
exit 0
endef

define Package/enhanced-dhcp/prerm
#!/bin/sh
if [ -z "$${IPKG_INSTROOT}" ]; then
	echo "Removing Enhanced DHCP..."
	/etc/init.d/enhanced_dhcp stop
	/etc/init.d/enhanced_dhcp disable
fi
exit 0
endef

$(eval $(call BuildPackage,enhanced-dhcp))