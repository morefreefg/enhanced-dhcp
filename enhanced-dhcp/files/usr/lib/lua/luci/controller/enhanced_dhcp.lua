-- Enhanced DHCP Manager v2.0 - LuCI Controller
-- Embeds HTML interface directly into LuCI

module("luci.controller.enhanced_dhcp", package.seeall)

function index()
	-- Main menu entry in Network section
	local page = entry({"admin", "network", "enhanced_dhcp"}, template("enhanced_dhcp"), _("Enhanced DHCP"), 60)
	page.dependent = false
	-- Remove ACL dependency for testing
	-- page.acl_depends = { "luci-app-enhanced-dhcp" }
end
