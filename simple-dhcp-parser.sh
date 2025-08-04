#!/bin/sh

# Simple DHCP Config Parser - Maximum Compatibility
# Parse hosts and tags from /etc/config/dhcp using basic shell commands

parse_dhcp_hosts() {
    local config_file="/etc/config/dhcp"
    local json_array="["
    local first=true
    local in_host=false
    local host_name=""
    local host_mac=""
    local host_ip=""
    local host_tag=""
    
    if [ ! -f "$config_file" ]; then
        echo "[]"
        return
    fi
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        
        case "$line" in
            "config host"*)
                # Start of new host section
                if [ "$in_host" = true ] && [ -n "$host_mac" ]; then
                    # Output previous host
                    if [ "$first" = true ]; then
                        first=false
                    else
                        json_array="$json_array,"
                    fi
                    
                    # Use defaults if empty
                    [ -z "$host_name" ] && host_name="Unknown"
                    [ -z "$host_ip" ] && host_ip="Auto"
                    [ -z "$host_tag" ] && host_tag="default"
                    
                    json_array="$json_array{\"mac\":\"$host_mac\",\"name\":\"$host_name\",\"ip\":\"$host_ip\",\"tag\":\"$host_tag\"}"
                fi
                
                # Reset for new host
                in_host=true
                host_name=""
                host_mac=""
                host_ip=""
                host_tag=""
                ;;
            "config "*|"")
                # End of host section
                if [ "$in_host" = true ] && [ -n "$host_mac" ]; then
                    # Output current host
                    if [ "$first" = true ]; then
                        first=false
                    else
                        json_array="$json_array,"
                    fi
                    
                    # Use defaults if empty
                    [ -z "$host_name" ] && host_name="Unknown"
                    [ -z "$host_ip" ] && host_ip="Auto"
                    [ -z "$host_tag" ] && host_tag="default"
                    
                    json_array="$json_array{\"mac\":\"$host_mac\",\"name\":\"$host_name\",\"ip\":\"$host_ip\",\"tag\":\"$host_tag\"}"
                fi
                in_host=false
                ;;
            *"option name"*)
                if [ "$in_host" = true ]; then
                    host_name=$(echo "$line" | sed "s/.*option name[[:space:]]*['\"][[:space:]]*//; s/[[:space:]]*['\"].*//")
                fi
                ;;
            *"list mac"*)
                if [ "$in_host" = true ]; then
                    host_mac=$(echo "$line" | sed "s/.*list mac[[:space:]]*['\"][[:space:]]*//; s/[[:space:]]*['\"].*//")
                fi
                ;;
            *"option ip"*)
                if [ "$in_host" = true ]; then
                    host_ip=$(echo "$line" | sed "s/.*option ip[[:space:]]*['\"][[:space:]]*//; s/[[:space:]]*['\"].*//")
                fi
                ;;
            *"list tag"*)
                if [ "$in_host" = true ]; then
                    host_tag=$(echo "$line" | sed "s/.*list tag[[:space:]]*['\"][[:space:]]*//; s/[[:space:]]*['\"].*//")
                fi
                ;;
        esac
    done < "$config_file"
    
    # Handle last host if file doesn't end with empty line/config
    if [ "$in_host" = true ] && [ -n "$host_mac" ]; then
        if [ "$first" = true ]; then
            first=false
        else
            json_array="$json_array,"
        fi
        
        # Use defaults if empty
        [ -z "$host_name" ] && host_name="Unknown"
        [ -z "$host_ip" ] && host_ip="Auto"
        [ -z "$host_tag" ] && host_tag="default"
        
        json_array="$json_array{\"mac\":\"$host_mac\",\"name\":\"$host_name\",\"ip\":\"$host_ip\",\"tag\":\"$host_tag\"}"
    fi
    
    json_array="$json_array]"
    echo "$json_array"
}

parse_dhcp_tags() {
    local config_file="/etc/config/dhcp"
    local json_array="["
    local first=true
    local in_tag=false
    local tag_name=""
    local tag_gateway=""
    local tag_dns=""
    
    if [ ! -f "$config_file" ]; then
        echo "[]"
        return
    fi
    
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
        
        case "$line" in
            "config tag "*)
                # Start of new tag section
                if [ "$in_tag" = true ] && [ -n "$tag_name" ]; then
                    # Output previous tag
                    if [ "$first" = true ]; then
                        first=false
                    else
                        json_array="$json_array,"
                    fi
                    
                    json_array="$json_array{\"name\":\"$tag_name\",\"description\":\"\",\"gateway\":\"$tag_gateway\",\"dns\":\"$tag_dns\"}"
                fi
                
                # Extract tag name
                tag_name=$(echo "$line" | sed "s/config tag[[:space:]]*['\"][[:space:]]*//; s/[[:space:]]*['\"].*//")
                in_tag=true
                tag_gateway=""
                tag_dns=""
                ;;
            "config "*|"")
                # End of tag section
                if [ "$in_tag" = true ] && [ -n "$tag_name" ]; then
                    # Output current tag
                    if [ "$first" = true ]; then
                        first=false
                    else
                        json_array="$json_array,"
                    fi
                    
                    json_array="$json_array{\"name\":\"$tag_name\",\"description\":\"\",\"gateway\":\"$tag_gateway\",\"dns\":\"$tag_dns\"}"
                fi
                in_tag=false
                ;;
            *"list dhcp_option"*)
                if [ "$in_tag" = true ]; then
                    option_value=$(echo "$line" | sed "s/.*list dhcp_option[[:space:]]*['\"][[:space:]]*//; s/[[:space:]]*['\"].*//")
                    case "$option_value" in
                        3,*)
                            tag_gateway="${option_value#3,}"
                            ;;
                        6,*)
                            tag_dns="${option_value#6,}"
                            ;;
                    esac
                fi
                ;;
        esac
    done < "$config_file"
    
    # Handle last tag if file doesn't end with empty line/config
    if [ "$in_tag" = true ] && [ -n "$tag_name" ]; then
        if [ "$first" = true ]; then
            first=false
        else
            json_array="$json_array,"
        fi
        
        json_array="$json_array{\"name\":\"$tag_name\",\"description\":\"\",\"gateway\":\"$tag_gateway\",\"dns\":\"$tag_dns\"}"
    fi
    
    json_array="$json_array]"
    echo "$json_array"
}

# Test the functions
echo "=== Testing DHCP Host Parsing ==="
parse_dhcp_hosts

echo ""
echo "=== Testing DHCP Tag Parsing ==="
parse_dhcp_tags