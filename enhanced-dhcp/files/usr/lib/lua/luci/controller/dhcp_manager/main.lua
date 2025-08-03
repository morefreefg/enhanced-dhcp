module("luci.controller.dhcp_manager.main", package.seeall)

function index()
	local uci = luci.model.uci.cursor()
	
	-- Check if enhanced_dhcp config exists
	if not uci:get_first("enhanced_dhcp", "global") then
		return
	end
	
	-- Main menu entry
	local page = entry({"admin", "network", "enhanced_dhcp"}, firstchild(), _("Enhanced DHCP"), 60)
	page.dependent = false
	page.acl_depends = { "luci-app-enhanced-dhcp" }
	
	-- Overview page
	page = entry({"admin", "network", "enhanced_dhcp", "overview"}, 
		template("dhcp_manager/overview"), _("Overview"), 1)
	page.leaf = true
	page.acl_depends = { "luci-app-enhanced-dhcp" }
	
	-- DHCP Tags management
	page = entry({"admin", "network", "enhanced_dhcp", "tags"}, 
		cbi("dhcp_manager/tags"), _("DHCP Tags"), 2)
	page.dependent = false
	page.acl_depends = { "luci-app-enhanced-dhcp" }
	
	-- Device management
	page = entry({"admin", "network", "enhanced_dhcp", "devices"}, 
		cbi("dhcp_manager/devices"), _("Device Management"), 3)
	page.dependent = false
	page.acl_depends = { "luci-app-enhanced-dhcp" }
	
	-- AJAX handlers
	page = entry({"admin", "network", "enhanced_dhcp", "ajax_get_devices"}, 
		call("ajax_get_devices"), nil)
	page.leaf = true
	
	page = entry({"admin", "network", "enhanced_dhcp", "ajax_apply_tag"}, 
		call("ajax_apply_tag"), nil)
	page.leaf = true
	
	page = entry({"admin", "network", "enhanced_dhcp", "ajax_get_leases"}, 
		call("ajax_get_leases"), nil)
	page.leaf = true
end

-- Get current DHCP leases
function ajax_get_leases()
	local http = luci.http
	local sys = require "luci.sys"
	local json = require "luci.json"
	
	http.prepare_content("application/json")
	
	local leases = {}
	local dhcp_leases = sys.dhcp_leases()
	
	for _, lease in ipairs(dhcp_leases) do
		table.insert(leases, {
			hostname = lease.hostname or "Unknown",
			ipaddr = lease.ipaddr,
			macaddr = lease.macaddr,
			leasetime = lease.expires
		})
	end
	
	http.write(json.encode({
		success = true,
		data = leases
	}))
end

-- Get devices from ARP table and DHCP static hosts
function ajax_get_devices()
	local http = luci.http
	local sys = require "luci.sys"
	local uci = luci.model.uci.cursor()
	local json = require "luci.json"
	
	http.prepare_content("application/json")
	
	local devices = {}
	local seen_macs = {}
	
	-- Get static DHCP hosts
	uci:foreach("dhcp", "host", function(section)
		if section.mac and not seen_macs[section.mac] then
			devices[section.mac] = {
				mac = section.mac,
				name = section.name or "Unknown",
				ip = section.ip or "Auto",
				tag = section.tag or "default",
				static = true
			}
			seen_macs[section.mac] = true
		end
	end)
	
	-- Get ARP table entries
	local arps = sys.net.arptable()
	for _, arp in ipairs(arps) do
		if arp["HW address"] and not seen_macs[arp["HW address"]] then
			devices[arp["HW address"]] = {
				mac = arp["HW address"],
				name = arp["Device"] or "Unknown", 
				ip = arp["IP address"] or "Unknown",
				tag = "default",
				static = false
			}
			seen_macs[arp["HW address"]] = true
		end
	end
	
	-- Convert to array
	local device_list = {}
	for mac, device in pairs(devices) do
		table.insert(device_list, device)
	end
	
	-- Sort by MAC address
	table.sort(device_list, function(a, b) return a.mac < b.mac end)
	
	http.write(json.encode({
		success = true,
		data = device_list
	}))
end

-- Apply tag to device
function ajax_apply_tag()
	local http = luci.http
	local uci = luci.model.uci.cursor()
	local json = require "luci.json"
	
	http.prepare_content("application/json")
	
	local mac = http.formvalue("mac")
	local tag = http.formvalue("tag")
	local name = http.formvalue("name")
	
	if not mac or not tag then
		http.write(json.encode({
			success = false,
			message = "Missing MAC address or tag"
		}))
		return
	end
	
	-- Validate MAC address format (support both : and - separators)
	mac = mac:upper()
	if not mac:match("^[0-9A-F][0-9A-F][:-][0-9A-F][0-9A-F][:-][0-9A-F][0-9A-F][:-][0-9A-F][0-9A-F][:-][0-9A-F][0-9A-F][:-][0-9A-F][0-9A-F]$") then
		http.write(json.encode({
			success = false,
			message = "Invalid MAC address format"
		}))
		return
	end
	
	-- Normalize MAC address to use colon separators
	mac = mac:gsub("-", ":")
	
	-- Check if tag exists
	local tag_exists = false
	uci:foreach("dhcp", "tag", function(section)
		if section[".name"] == tag then
			tag_exists = true
			return false
		end
	end)
	
	if not tag_exists and tag ~= "default" then
		http.write(json.encode({
			success = false,
			message = "Tag does not exist: " .. tag
		}))
		return
	end
	
	-- Remove existing host entry for this MAC
	local removed = false
	uci:foreach("dhcp", "host", function(section)
		if section.mac == mac then
			uci:delete("dhcp", section[".name"])
			removed = true
			return false
		end
	end)
	
	-- Add new host entry
	local section_name = uci:add("dhcp", "host")
	uci:set("dhcp", section_name, "mac", mac)
	uci:set("dhcp", section_name, "name", name or "device_" .. mac:gsub(":", ""))
	
	if tag ~= "default" then
		uci:set("dhcp", section_name, "tag", tag)
	end
	
	-- Commit changes
	local commit_success = uci:commit("dhcp")
	if not commit_success then
		http.write(json.encode({
			success = false,
			message = "Failed to save configuration"
		}))
		return
	end
	
	-- Log the change
	luci.sys.call(string.format("logger -t enhanced_dhcp 'Applied tag %s to device %s (%s)'", 
		tag, mac, name or "Unknown"))
	
	-- Restart dnsmasq
	luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null 2>&1 &")
	
	http.write(json.encode({
		success = true,
		message = "Tag applied successfully"
	}))
end