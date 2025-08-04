-- Enhanced DHCP Manager v2.0 - LuCI Controller
-- Minimal LuCI integration - redirects to standalone HTML interface
-- Maximum compatibility across LuCI versions

module("luci.controller.enhanced_dhcp_v2", package.seeall)

function index()
	-- Main menu entry in Network section (replaces v1)
	local page = entry({"admin", "network", "enhanced_dhcp"}, template("enhanced_dhcp_v2"), _("Enhanced DHCP"), 60)
	page.dependent = false
	page.acl_depends = { "luci-app-enhanced-dhcp-v2" }
end

-- Redirect to standalone HTML interface
function redirect_to_html()
	local http = require "luci.http"
	
	-- Get the current host and protocol
	local host = http.getenv("HTTP_HOST") or "router"
	local scheme = http.getenv("REQUEST_SCHEME") or "http"
	
	-- Redirect to standalone HTML interface
	local redirect_url = string.format("%s://%s/enhanced-dhcp/", scheme, host)
	
	http.header("Cache-Control", "no-cache")
	http.redirect(redirect_url)
end

-- Optional API proxy for same-origin requests (if needed)
function api_proxy()
	local http = require "luci.http"
	local sys = require "luci.sys"
	
	-- Get the path info for API endpoint
	local path_info = http.getenv("PATH_INFO") or ""
	local query_string = http.getenv("QUERY_STRING") or ""
	local request_method = http.getenv("REQUEST_METHOD") or "GET"
	
	-- Forward to CGI API
	local api_url = "/cgi-bin/enhanced-dhcp-api" .. path_info
	if query_string ~= "" then
		api_url = api_url .. "?" .. query_string
	end
	
	-- Simple proxy using wget/curl if available
	local cmd
	if request_method == "GET" then
		cmd = string.format("wget -q -O - 'http://localhost%s' 2>/dev/null || curl -s 'http://localhost%s' 2>/dev/null", api_url, api_url)
	else
		-- For POST requests, just redirect to API
		http.redirect("/cgi-bin/enhanced-dhcp-api" .. path_info)
		return
	end
	
	local result = sys.exec(cmd)
	if result and result ~= "" then
		http.prepare_content("application/json")
		http.write(result)
	else
		-- Fallback: redirect to direct API
		http.redirect("/cgi-bin/enhanced-dhcp-api" .. path_info)
	end
end