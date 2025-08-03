local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local json = require "luci.json"

-- Create map for DHCP configuration
m = Map("dhcp", translate("Device Management"), 
	translate("Manage DHCP tag assignments for network devices. " ..
		"Devices can be assigned different DHCP option templates to receive specific network settings."))

-- Add JavaScript for dynamic functionality
m:append(Template("dhcp_manager/devices_js"))

-- Auto-discovery section
s1 = m:section(SimpleSection, translate("Device Discovery"))
s1.template = "dhcp_manager/device_discovery"

-- Manual device addition section
s2 = m:section(TypedSection, "host", translate("Device Configuration"))
s2.anonymous = true
s2.addremove = true
s2.template = "cbi/tblsection"
s2.sortable = true

-- Add a device manually
function s2.create(self, section)
	local mac = luci.http.formvalue("cbi.cts." .. self.config .. "." .. self.sectiontype .. ".mac")
	if mac and mac ~= "" then
		-- Validate and normalize MAC address
		mac = mac:upper():gsub("-", ":")
		if not mac:match("^[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]$") then
			self.map:error(translate("Invalid MAC address format"))
			return nil
		end
		
		-- Check if MAC already exists
		local exists = false
		uci:foreach("dhcp", "host", function(host)
			if host.mac and host.mac:lower() == mac:lower() then
				exists = true
				return false
			end
		end)
		
		if exists then
			self.map:error(translate("Device with this MAC address already exists"))
			return nil
		end
		
		return TypedSection.create(self, section)
	end
	return nil
end

-- Device name
name = s2:option(Value, "name", translate("Device Name"))
name.width = "20%"
name.placeholder = translate("Device Name")

-- MAC address
mac = s2:option(Value, "mac", translate("MAC Address"))
mac.width = "18%"
mac.datatype = "macaddr"
mac.placeholder = "00:11:22:33:44:55"

-- IP address (optional)
ip = s2:option(Value, "ip", translate("IP Address"))
ip.width = "15%"
ip.datatype = "ip4addr"
ip.placeholder = translate("Auto")

function ip.write(self, section, value)
	if value and value ~= "" and value ~= "Auto" then
		Value.write(self, section, value)
	else
		uci:delete("dhcp", section, "ip")
	end
end

-- Get available tags for dropdown
function get_available_tags()
	local tags = {{"default", translate("Default")}}
	
	uci:foreach("dhcp", "tag", function(section)
		table.insert(tags, {section[".name"], section[".name"]})
	end)
	
	return tags
end

-- DHCP Tag assignment
tag = s2:option(ListValue, "tag", translate("DHCP Tag"))
tag.width = "15%"

function tag.cfgvalue(self, section)
	return Value.cfgvalue(self, section) or "default"
end

-- Populate tag options
for _, tag_option in ipairs(get_available_tags()) do
	tag:value(tag_option[1], tag_option[2])
end

-- Current IP from DHCP leases
current_ip = s2:option(DummyValue, "_current_ip", translate("Current IP"))
current_ip.width = "12%"

function current_ip.cfgvalue(self, section)
	local device_mac = uci:get("dhcp", section, "mac")
	if device_mac then
		local leases = sys.dhcp_leases()
		for _, lease in ipairs(leases) do
			if lease.macaddr and lease.macaddr:lower() == device_mac:lower() then
				return lease.ipaddr or translate("Offline")
			end
		end
	end
	return translate("Unknown")
end

-- Status
status = s2:option(DummyValue, "_status", translate("Status"))
status.width = "10%"

function status.cfgvalue(self, section)
	local device_mac = uci:get("dhcp", section, "mac")
	if device_mac then
		local leases = sys.dhcp_leases()
		for _, lease in ipairs(leases) do
			if lease.macaddr and lease.macaddr:lower() == device_mac:lower() then
				return translate("Online")
			end
		end
	end
	return translate("Offline")
end

-- Tag details
tag_details = s2:option(DummyValue, "_tag_details", translate("Tag Details"))
tag_details.width = "10%"

function tag_details.cfgvalue(self, section)
	local device_tag = uci:get("dhcp", section, "tag") or "default"
	if device_tag == "default" then
		return translate("Default")
	else
		-- Get tag configuration
		local gateway = ""
		local dns = ""
		local options = uci:get("dhcp", device_tag, "dhcp_option") or {}
		
		for _, opt in ipairs(options) do
			local gw = opt:match("^3,(.+)$")
			if gw then gateway = gw end
			
			local dns_servers = opt:match("^6,(.+)$")
			if dns_servers then dns = dns_servers end
		end
		
		if gateway ~= "" or dns ~= "" then
			return string.format("GW: %s<br/>DNS: %s", 
				gateway ~= "" and gateway or "N/A", 
				dns ~= "" and dns or "N/A")
		else
			return translate("Custom")
		end
	end
end

-- Add quick assignment section
s3 = m:section(SimpleSection, translate("Quick Device Assignment"))
s3.template = "dhcp_manager/quick_assign"

-- Custom validate function to check MAC address format
function m.save(self)
	local has_errors = false
	
	-- Validate all MAC addresses
	uci:foreach("dhcp", "host", function(section)
		local mac_addr = uci:get("dhcp", section[".name"], "mac")
		if mac_addr and not mac_addr:match("^[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]:[%x][%x]$") then
			self:error(translate("Invalid MAC address format: ") .. mac_addr)
			has_errors = true
		end
	end)
	
	if has_errors then
		return false
	end
	
	return Map.save(self)
end

-- Restart dnsmasq after commit
function m.on_commit(self)
	luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null 2>&1 &")
end

return m