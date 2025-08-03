local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local ip = require "luci.ip"

-- Create map for DHCP configuration
m = Map("dhcp", translate("DHCP Tags Management"), 
	translate("Create and manage DHCP option templates. " ..
		"Tags define different gateway and DNS settings that can be applied to devices."))

-- Tags section
s = m:section(TypedSection, "tag", translate("DHCP Tags"))
s.anonymous = false  -- Allow named sections so user can input tag name
s.addremove = true
s.template = "cbi/tblsection"
s.sortable = true

-- Custom create function to ensure proper tag creation
function s.create(self, section)
	-- Ensure we have a section name
	if not section or section == "" then
		self.map:error(translate("Tag name is required"))
		return nil
	end
	
	-- Basic validation
	if #section < 2 or #section > 32 then
		self.map:error(translate("Tag name must be between 2 and 32 characters"))
		return nil
	end
	
	if not section:match("^[a-zA-Z0-9_%-]+$") then
		self.map:error(translate("Tag name can only contain letters, numbers, underscores and hyphens"))
		return nil
	end
	
	-- Check if already exists
	if uci:get("dhcp", section) then
		self.map:error(translate("Tag name already exists"))
		return nil
	end
	
	return TypedSection.create(self, section)
end

-- Tag name (display the section name)
name = s:option(DummyValue, ".name", translate("Tag Name"))
name.width = "20%"

function name.cfgvalue(self, section)
	return section
end

-- Gateway option
gateway = s:option(Value, "gateway", translate("Gateway"))
gateway.datatype = "ip4addr"
gateway.width = "25%"
gateway.placeholder = "192.168.1.1"

function gateway.write(self, section, value)
	if value and value ~= "" then
		-- Remove existing gateway option
		local options = uci:get("dhcp", section, "dhcp_option") or {}
		local new_options = {}
		for _, opt in ipairs(options) do
			if not opt:match("^3,") then
				table.insert(new_options, opt)
			end
		end
		-- Add new gateway option
		table.insert(new_options, "3," .. value)
		uci:set("dhcp", section, "dhcp_option", new_options)
	end
end

function gateway.cfgvalue(self, section)
	local options = uci:get("dhcp", section, "dhcp_option") or {}
	for _, opt in ipairs(options) do
		local gateway_ip = opt:match("^3,(.+)$")
		if gateway_ip then
			return gateway_ip
		end
	end
	return ""
end

-- DNS servers option
dns_servers = s:option(Value, "dns_servers", translate("DNS Servers"))
dns_servers.width = "30%"
dns_servers.placeholder = "8.8.8.8,8.8.4.4"

function dns_servers.validate(self, value)
	if value and value ~= "" then
		-- Split by comma and validate each IP
		for ip_addr in value:gmatch("[^,]+") do
			local trimmed = ip_addr:match("^%s*(.-)%s*$") -- trim whitespace
			if not ip.IPv4(trimmed) then
				return nil, translate("Invalid DNS server IP address: ") .. trimmed
			end
		end
	end
	return value
end

function dns_servers.write(self, section, value)
	if value and value ~= "" then
		-- Remove existing DNS option
		local options = uci:get("dhcp", section, "dhcp_option") or {}
		local new_options = {}
		for _, opt in ipairs(options) do
			if not opt:match("^6,") then
				table.insert(new_options, opt)
			end
		end
		-- Add new DNS option
		local dns_list = {}
		for ip_addr in value:gmatch("[^,]+") do
			local trimmed = ip_addr:match("^%s*(.-)%s*$")
			table.insert(dns_list, trimmed)
		end
		table.insert(new_options, "6," .. table.concat(dns_list, ","))
		uci:set("dhcp", section, "dhcp_option", new_options)
	end
end

function dns_servers.cfgvalue(self, section)
	local options = uci:get("dhcp", section, "dhcp_option") or {}
	for _, opt in ipairs(options) do
		local dns_ips = opt:match("^6,(.+)$")
		if dns_ips then
			return dns_ips
		end
	end
	return ""
end

-- Description
description = s:option(Value, "description", translate("Description"))
description.width = "20%"
description.placeholder = translate("Optional description")

-- Add validation to prevent deletion if tag is in use
function s.remove(self, section)
	-- Check if tag is used by any hosts
	local in_use = false
	local using_hosts = {}
	
	uci:foreach("dhcp", "host", function(host)
		if host.tag == section then
			in_use = true
			table.insert(using_hosts, host.name or host.mac or "Unknown")
		end
	end)
	
	if in_use then
		self.map:error(translate("Cannot delete tag: it is used by devices: ") .. 
			table.concat(using_hosts, ", "))
		return false
	end
	
	return TypedSection.remove(self, section)
end

-- Add default tag creation section
s2 = m:section(NamedSection, "default_tag", "", translate("Default Tag"))
s2.addremove = false

-- Default tag info
default_info = s2:option(DummyValue, "_info", translate("Default Tag Information"))
default_info.template = "cbi/nullsection"

function default_info.cfgvalue(self, section)
	return translate("The default tag is automatically applied to devices without a specific tag assignment. " ..
		"Configure the default gateway and DNS settings below.")
end

-- Default gateway
default_gateway = s2:option(Value, "default_gateway", translate("Default Gateway"))
default_gateway.datatype = "ip4addr"
default_gateway.placeholder = "192.168.1.1"

function default_gateway.cfgvalue(self, section)
	-- Get from main dnsmasq section
	return uci:get("dhcp", "@dnsmasq[0]", "defaultroute") or 
		uci:get("network", "lan", "ipaddr") or "192.168.1.1"
end

function default_gateway.write(self, section, value)
	if value and value ~= "" then
		uci:set("dhcp", "@dnsmasq[0]", "defaultroute", value)
	end
end

-- Default DNS
default_dns = s2:option(Value, "default_dns", translate("Default DNS Servers"))
default_dns.placeholder = "192.168.1.1"

function default_dns.cfgvalue(self, section)
	local dns_list = uci:get_list("dhcp", "@dnsmasq[0]", "server") or {}
	return table.concat(dns_list, ",")
end

function default_dns.validate(self, value)
	if value and value ~= "" then
		for ip_addr in value:gmatch("[^,]+") do
			local trimmed = ip_addr:match("^%s*(.-)%s*$")
			if not ip.IPv4(trimmed) then
				return nil, translate("Invalid DNS server IP address: ") .. trimmed
			end
		end
	end
	return value
end

function default_dns.write(self, section, value)
	if value and value ~= "" then
		local dns_list = {}
		for ip_addr in value:gmatch("[^,]+") do
			local trimmed = ip_addr:match("^%s*(.-)%s*$")
			table.insert(dns_list, trimmed)
		end
		uci:set_list("dhcp", "@dnsmasq[0]", "server", dns_list)
	end
end

-- Custom commit function to restart dnsmasq
function m.on_commit(self)
	luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null 2>&1 &")
end

return m