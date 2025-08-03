#!/bin/bash
# Enhanced DHCP - Complete Build, Deploy and Test Script
# Builds IPK package, deploys to target device, and runs comprehensive tests

set -e  # Exit on any error

# Configuration
TARGET_IP="192.168.10.2"
TARGET_USER="root"
TARGET_PATH="/tmp"
LOCAL_IPK_PATH="output/luci-app-enhanced-dhcp_1.0.0-1_all.ipk"
PACKAGE_NAME="luci-app-enhanced-dhcp"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if device is reachable
check_device() {
    log_info "Checking if target device $TARGET_IP is reachable..."
    if ping -c 1 -W 3 $TARGET_IP >/dev/null 2>&1; then
        log_success "Device $TARGET_IP is reachable"
        return 0
    else
        log_error "Device $TARGET_IP is not reachable"
        return 1
    fi
}

# Function to build IPK package
build_package() {
    log_info "Building Enhanced DHCP IPK package..."
    
    if [ -f "./build-optimized.sh" ]; then
        chmod +x ./build-optimized.sh
        ./build-optimized.sh
        
        if [ -f "$LOCAL_IPK_PATH" ]; then
            local size=$(ls -lh "$LOCAL_IPK_PATH" | awk '{print $5}')
            log_success "Package built successfully: $LOCAL_IPK_PATH ($size)"
            return 0
        else
            log_error "Package build failed - IPK file not found"
            return 1
        fi
    else
        log_error "Build script not found: ./build-optimized.sh"
        return 1
    fi
}

# Function to deploy package to target device
deploy_package() {
    log_info "Deploying package to $TARGET_USER@$TARGET_IP:$TARGET_PATH..."
    
    if scp "$LOCAL_IPK_PATH" "$TARGET_USER@$TARGET_IP:$TARGET_PATH/"; then
        log_success "Package deployed successfully"
        return 0
    else
        log_error "Package deployment failed"
        return 1
    fi
}

# Function to install package on target device
install_package() {
    log_info "Installing package on target device..."
    
    local remote_ipk="$TARGET_PATH/$(basename $LOCAL_IPK_PATH)"
    
    # Try opkg install first
    if ssh "$TARGET_USER@$TARGET_IP" "opkg update && opkg install '$remote_ipk'" 2>/dev/null; then
        log_success "Package installed successfully via opkg"
        return 0
    else
        log_warning "opkg install failed, trying manual installation..."
        
        # Manual installation fallback
        ssh "$TARGET_USER@$TARGET_IP" "
            cd $TARGET_PATH
            ar x '$(basename $LOCAL_IPK_PATH)'
            tar -xzf data.tar.gz -C /
            if [ -f control.tar.gz ]; then
                tar -xzf control.tar.gz
                if [ -f postinst ]; then
                    chmod +x postinst && ./postinst
                fi
            fi
            /etc/init.d/rpcd restart
            rm -f debian-binary control.tar.gz data.tar.gz postinst prerm
        "
        
        if [ $? -eq 0 ]; then
            log_success "Package installed successfully via manual method"
            return 0
        else
            log_error "Package installation failed"
            return 1
        fi
    fi
}

# Function to test package installation
test_installation() {
    log_info "Testing package installation..."
    
    local test_results=""
    
    # Test 1: Check if package is installed
    log_info "Test 1: Checking package installation..."
    if ssh "$TARGET_USER@$TARGET_IP" "opkg list-installed | grep -q '$PACKAGE_NAME'" 2>/dev/null; then
        log_success "✓ Package is installed"
        test_results="$test_results\n✓ Package installation: PASS"
    else
        log_warning "⚠ Package not found in opkg list (manual install?)"
        test_results="$test_results\n⚠ Package installation: MANUAL"
    fi
    
    # Test 2: Check LuCI controller file
    log_info "Test 2: Checking LuCI controller file..."
    if ssh "$TARGET_USER@$TARGET_IP" "[ -f /usr/lib/lua/luci/controller/enhanced_dhcp.lua ]"; then
        log_success "✓ LuCI controller file exists"
        test_results="$test_results\n✓ Controller file: PASS"
    else
        log_error "✗ LuCI controller file missing"
        test_results="$test_results\n✗ Controller file: FAIL"
    fi
    
    # Test 3: Check UCI configuration
    log_info "Test 3: Checking UCI configuration..."
    if ssh "$TARGET_USER@$TARGET_IP" "uci show enhanced_dhcp" >/dev/null 2>&1; then
        log_success "✓ UCI configuration accessible"
        test_results="$test_results\n✓ UCI config: PASS"
    else
        log_warning "⚠ UCI configuration not found (may be default)"
        test_results="$test_results\n⚠ UCI config: DEFAULT"
    fi
    
    # Test 4: Check init script
    log_info "Test 4: Checking init script..."
    if ssh "$TARGET_USER@$TARGET_IP" "[ -f /etc/init.d/enhanced_dhcp ]"; then
        local status=$(ssh "$TARGET_USER@$TARGET_IP" "/etc/init.d/enhanced_dhcp status 2>/dev/null || echo 'unknown'")
        log_success "✓ Init script exists (status: $status)"
        test_results="$test_results\n✓ Init script: PASS ($status)"
    else
        log_warning "⚠ Init script not found"
        test_results="$test_results\n⚠ Init script: MISSING"
    fi
    
    # Test 5: Check LuCI menu integration
    log_info "Test 5: Testing LuCI integration..."
    if ssh "$TARGET_USER@$TARGET_IP" "lua -e 'require(\"luci.controller.enhanced_dhcp\")'" 2>/dev/null; then
        log_success "✓ LuCI module loads successfully"
        test_results="$test_results\n✓ LuCI integration: PASS"
    else
        log_error "✗ LuCI module loading failed"
        test_results="$test_results\n✗ LuCI integration: FAIL"
    fi
    
    # Test 6: Check JSON compatibility
    log_info "Test 6: Testing JSON compatibility..."
    if ssh "$TARGET_USER@$TARGET_IP" "lua -e 'require(\"luci.jsonc\")'" 2>/dev/null; then
        log_success "✓ JSON module (luci.jsonc) available"
        test_results="$test_results\n✓ JSON compatibility: PASS"
    else
        log_error "✗ JSON module (luci.jsonc) not available"
        test_results="$test_results\n✗ JSON compatibility: FAIL"
    fi
    
    # Test 7: Check DHCP leases reading
    log_info "Test 7: Testing DHCP leases access..."
    if ssh "$TARGET_USER@$TARGET_IP" "[ -r /var/dhcp.leases ]"; then
        local lease_count=$(ssh "$TARGET_USER@$TARGET_IP" "wc -l < /var/dhcp.leases 2>/dev/null || echo 0")
        log_success "✓ DHCP leases file accessible ($lease_count leases)"
        test_results="$test_results\n✓ DHCP leases: PASS ($lease_count leases)"
    else
        log_warning "⚠ DHCP leases file not accessible"
        test_results="$test_results\n⚠ DHCP leases: LIMITED"
    fi
    
    # Print test summary
    echo ""
    log_info "=== TEST SUMMARY ==="
    echo -e "$test_results"
    echo ""
    
    # Overall result
    if echo "$test_results" | grep -q "FAIL"; then
        log_error "Some tests failed - manual intervention may be required"
        return 1
    else
        log_success "All critical tests passed - Enhanced DHCP is ready!"
        return 0
    fi
}

# Function to show access information
show_access_info() {
    log_info "=== ACCESS INFORMATION ==="
    echo "Web Interface: http://$TARGET_IP/cgi-bin/luci"
    echo "Enhanced DHCP: Network → Enhanced DHCP"
    echo ""
    echo "SSH Access: ssh $TARGET_USER@$TARGET_IP"
    echo ""
    echo "Available pages:"
    echo "  • Overview: Network → Enhanced DHCP → Overview"
    echo "  • Devices:  Network → Enhanced DHCP → Devices" 
    echo "  • Tags:     Network → Enhanced DHCP → Tags"
    echo ""
}

# Function to cleanup remote files
cleanup_remote() {
    log_info "Cleaning up temporary files on target device..."
    ssh "$TARGET_USER@$TARGET_IP" "rm -f $TARGET_PATH/$(basename $LOCAL_IPK_PATH)" 2>/dev/null || true
}

# Main execution
main() {
    echo "======================================================"
    echo "Enhanced DHCP - Complete Build, Deploy & Test Script"
    echo "======================================================"
    echo ""
    
    # Check prerequisites
    if ! command -v ssh >/dev/null 2>&1; then
        log_error "ssh command not found"
        exit 1
    fi
    
    if ! command -v scp >/dev/null 2>&1; then
        log_error "scp command not found"  
        exit 1
    fi
    
    # Step 1: Check device connectivity
    if ! check_device; then
        log_error "Cannot proceed - target device unreachable"
        exit 1
    fi
    
    # Step 2: Build package
    if ! build_package; then
        log_error "Build failed - cannot proceed"
        exit 1
    fi
    
    # Step 3: Deploy package
    if ! deploy_package; then
        log_error "Deployment failed - cannot proceed"
        exit 1
    fi
    
    # Step 4: Install package
    if ! install_package; then
        log_error "Installation failed"
        cleanup_remote
        exit 1
    fi
    
    # Step 5: Test installation
    echo ""
    log_info "Waiting 3 seconds for services to stabilize..."
    sleep 3
    
    if test_installation; then
        log_success "🎉 Enhanced DHCP deployment completed successfully!"
        show_access_info
    else
        log_warning "Deployment completed but some tests failed"
        show_access_info
    fi
    
    # Step 6: Cleanup
    cleanup_remote
    
    echo ""
    log_success "Script completed!"
}

# Handle interrupts gracefully
trap 'log_warning "Script interrupted"; cleanup_remote; exit 1' INT TERM

# Run main function
main "$@"