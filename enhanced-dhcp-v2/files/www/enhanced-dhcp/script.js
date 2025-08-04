/**
 * Enhanced DHCP Manager - JavaScript Frontend
 * Pure JavaScript implementation with no external dependencies
 */

class EnhancedDHCPManager {
    constructor() {
        this.apiBase = '/cgi-bin/enhanced-dhcp-api';
        this.deviceTypes = null;
        this.currentData = {
            devices: [],
            tags: [],
            leases: [],
            stats: {}
        };
        this.refreshInterval = null;
        this.currentDevice = null;
        
        this.init();
    }

    async init() {
        this.setupEventListeners();
        this.setupTabs();
        this.startAutoRefresh();
        
        // Load device types
        await this.loadDeviceTypes();
        
        // Initial data load
        await this.loadAllData();
    }

    setupEventListeners() {
        // Tab switching
        document.querySelectorAll('.tab-button').forEach(button => {
            button.addEventListener('click', (e) => {
                this.switchTab(e.target.dataset.tab);
            });
        });

        // Refresh buttons
        document.getElementById('refresh-devices')?.addEventListener('click', () => {
            this.loadDevices();
        });

        // Device discovery
        document.getElementById('discover-devices')?.addEventListener('click', () => {
            this.discoverDevices();
        });

        // Device search and filter
        document.getElementById('device-search')?.addEventListener('input', (e) => {
            this.filterDevices(e.target.value, document.getElementById('device-filter').value);
        });

        document.getElementById('device-filter')?.addEventListener('change', (e) => {
            this.filterDevices(document.getElementById('device-search').value, e.target.value);
        });

        // Tag management
        document.getElementById('create-tag-btn')?.addEventListener('click', () => {
            this.showCreateTagForm();
        });

        document.getElementById('save-tag-btn')?.addEventListener('click', () => {
            this.saveTag();
        });

        document.getElementById('cancel-tag-btn')?.addEventListener('click', () => {
            this.hideCreateTagForm();
        });

        // Quick assignment
        document.getElementById('apply-tag-btn')?.addEventListener('click', () => {
            this.applyQuickTag();
        });

        document.getElementById('cancel-assign-btn')?.addEventListener('click', () => {
            this.hideQuickAssign();
        });

        // Modal handling
        document.getElementById('confirm-yes')?.addEventListener('click', () => {
            this.confirmAction();
        });

        document.getElementById('confirm-no')?.addEventListener('click', () => {
            this.hideConfirmModal();
        });
    }

    setupTabs() {
        // Set initial active tab
        this.switchTab('overview');
    }

    switchTab(tabName) {
        // Update tab buttons
        document.querySelectorAll('.tab-button').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');

        // Update tab content
        document.querySelectorAll('.tab-content').forEach(content => {
            content.classList.remove('active');
        });
        document.getElementById(tabName).classList.add('active');

        // Load data for active tab
        this.loadTabData(tabName);
    }

    async loadTabData(tabName) {
        switch (tabName) {
            case 'overview':
                await this.loadOverview();
                break;
            case 'devices':
                await this.loadDevices();
                break;
            case 'tags':
                await this.loadTags();
                break;
        }
    }

    async loadAllData() {
        try {
            await Promise.all([
                this.loadStats(),
                this.loadDevices(),
                this.loadTags(),
                this.loadLeases()
            ]);
            this.updateLastUpdateTime();
        } catch (error) {
            this.showMessage('Error loading data: ' + error.message, 'error');
        }
    }

    async apiRequest(endpoint, method = 'GET', data = null) {
        const url = this.apiBase + endpoint;
        const options = {
            method,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        };

        if (data && method === 'POST') {
            options.body = new URLSearchParams(data).toString();
        }

        try {
            const response = await fetch(url, options);
            const result = await response.json();
            
            if (!result.success) {
                throw new Error(result.error || 'API request failed');
            }
            
            return result.data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    }

    async loadDeviceTypes() {
        try {
            const response = await fetch('device-types.json');
            this.deviceTypes = await response.json();
        } catch (error) {
            console.warn('Could not load device types:', error);
            this.deviceTypes = { mac_prefixes: {}, device_categories: {}, default_tags: {} };
        }
    }

    async loadStats() {
        try {
            const stats = await this.apiRequest('/stats');
            this.currentData.stats = stats;
            this.updateStatsDisplay();
        } catch (error) {
            console.error('Error loading stats:', error);
        }
    }

    async loadDevices() {
        try {
            const devices = await this.apiRequest('/devices');
            this.currentData.devices = devices;
            this.updateDevicesTable();
            this.updateQuickAssignTags();
        } catch (error) {
            console.error('Error loading devices:', error);
            this.showMessage('Error loading devices: ' + error.message, 'error');
        }
    }

    async loadTags() {
        try {
            const tags = await this.apiRequest('/tags');
            this.currentData.tags = tags;
            this.updateTagsTable();
            this.updateQuickAssignTags();
        } catch (error) {
            console.error('Error loading tags:', error);
            this.showMessage('Error loading tags: ' + error.message, 'error');
        }
    }

    async loadLeases() {
        try {
            const leases = await this.apiRequest('/leases');
            this.currentData.leases = leases;
            this.updateLeasesTable();
        } catch (error) {
            console.error('Error loading leases:', error);
        }
    }

    async loadOverview() {
        await Promise.all([
            this.loadStats(),
            this.loadLeases(),
            this.loadTags()
        ]);
        this.updateTagsSummary();
    }

    updateStatsDisplay() {
        const stats = this.currentData.stats;
        document.getElementById('total-tags').textContent = stats.total_tags || 0;
        document.getElementById('total-devices').textContent = stats.total_devices || 0;
        document.getElementById('online-devices').textContent = stats.online_devices || 0;
    }

    updateDevicesTable() {
        const tbody = document.querySelector('#devices-table tbody');
        if (!tbody) return;

        if (this.currentData.devices.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" class="loading">No devices found</td></tr>';
            return;
        }

        tbody.innerHTML = this.currentData.devices.map(device => {
            const deviceType = this.guessDeviceType(device.name, device.mac);
            const statusClass = device.type === 'lease' ? 'status-online' : 'status-offline';
            const statusText = device.type === 'lease' ? '🟢 Online' : '⚫ Offline';
            
            return `
                <tr data-mac="${device.mac}">
                    <td>
                        <div class="device-type">
                            <span class="device-icon">${deviceType.icon}</span>
                            <span title="${device.mac}">${this.escapeHtml(device.name)}</span>
                        </div>
                    </td>
                    <td><code>${device.mac}</code></td>
                    <td>${device.ip}</td>
                    <td class="${statusClass}">${statusText}</td>
                    <td>
                        <span class="tag-badge">${device.tag}</span>
                    </td>
                    <td>
                        <button class="btn btn-sm btn-primary" onclick="dhcpManager.showQuickAssign('${device.mac}', '${this.escapeHtml(device.name)}')">
                            🏷️ Assign
                        </button>
                    </td>
                </tr>
            `;
        }).join('');
    }

    updateTagsTable() {
        const tbody = document.querySelector('#tags-table tbody');
        if (!tbody) return;

        // Add default tag row
        let html = `
            <tr>
                <td><strong>default</strong> <em>(built-in)</em></td>
                <td>Auto</td>
                <td>Auto</td>
                <td>Default DHCP settings</td>
                <td>${this.countDevicesWithTag('default')}</td>
                <td><em>Cannot delete</em></td>
            </tr>
        `;

        // Add custom tags
        html += this.currentData.tags.map(tag => `
            <tr>
                <td><strong>${this.escapeHtml(tag.name)}</strong></td>
                <td>${tag.gateway || 'Not set'}</td>
                <td>${tag.dns || 'Not set'}</td>
                <td>${this.escapeHtml(tag.description || '')}</td>
                <td>${this.countDevicesWithTag(tag.name)}</td>
                <td>
                    <button class="btn btn-sm btn-danger" onclick="dhcpManager.deleteTag('${tag.name}')">
                        🗑️ Delete
                    </button>
                </td>
            </tr>
        `).join('');

        tbody.innerHTML = html;
    }

    updateLeasesTable() {
        const tbody = document.querySelector('#leases-table tbody');
        if (!tbody) return;

        if (this.currentData.leases.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="loading">No active leases</td></tr>';
            return;
        }

        tbody.innerHTML = this.currentData.leases.map(lease => {
            const deviceTag = this.getDeviceTag(lease.macaddr);
            const leaseTime = lease.timestamp === '0' ? 'Static' : new Date(lease.timestamp * 1000).toLocaleString();
            
            return `
                <tr>
                    <td>${this.escapeHtml(lease.hostname)}</td>
                    <td>${lease.ipaddr}</td>
                    <td><code>${lease.macaddr}</code></td>
                    <td>${leaseTime}</td>
                    <td><span class="tag-badge">${deviceTag}</span></td>
                </tr>
            `;
        }).join('');
    }

    updateTagsSummary() {
        const tbody = document.querySelector('#tags-summary-table tbody');
        if (!tbody) return;

        // Default tag summary
        let html = `
            <tr>
                <td><strong>default</strong></td>
                <td>Auto</td>
                <td>Auto</td>
                <td>${this.countDevicesWithTag('default')}</td>
            </tr>
        `;

        // Custom tags summary
        html += this.currentData.tags.map(tag => `
            <tr>
                <td><strong>${this.escapeHtml(tag.name)}</strong></td>
                <td>${tag.gateway || 'Not set'}</td>
                <td>${tag.dns || 'Not set'}</td>
                <td>${this.countDevicesWithTag(tag.name)}</td>
            </tr>
        `).join('');

        tbody.innerHTML = html;
    }

    updateQuickAssignTags() {
        const select = document.getElementById('quick-assign-tag');
        if (!select) return;

        select.innerHTML = '<option value="default">default (built-in)</option>' +
            this.currentData.tags.map(tag => 
                `<option value="${tag.name}">${this.escapeHtml(tag.name)}</option>`
            ).join('');
    }

    filterDevices(searchTerm, filterType) {
        const tbody = document.querySelector('#devices-table tbody');
        const rows = tbody.querySelectorAll('tr');

        rows.forEach(row => {
            const mac = row.dataset.mac;
            if (!mac) return;

            const device = this.currentData.devices.find(d => d.mac === mac);
            if (!device) return;

            const matchesSearch = !searchTerm || 
                device.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                device.mac.toLowerCase().includes(searchTerm.toLowerCase()) ||
                device.ip.toLowerCase().includes(searchTerm.toLowerCase());

            const matchesFilter = !filterType || device.type === filterType;

            row.style.display = matchesSearch && matchesFilter ? '' : 'none';
        });
    }

    showQuickAssign(mac, name) {
        this.currentDevice = { mac, name };
        document.getElementById('quick-assign-device').textContent = `${name} (${mac})`;
        document.getElementById('quick-assign-name').value = name;
        document.getElementById('quick-assign-panel').style.display = 'block';
        document.getElementById('quick-assign-panel').scrollIntoView({ behavior: 'smooth' });
    }

    hideQuickAssign() {
        document.getElementById('quick-assign-panel').style.display = 'none';
        this.currentDevice = null;
    }

    async applyQuickTag() {
        if (!this.currentDevice) return;

        const tag = document.getElementById('quick-assign-tag').value;
        const name = document.getElementById('quick-assign-name').value.trim();

        if (!tag) {
            this.showMessage('Please select a tag', 'warning');
            return;
        }

        try {
            this.showLoading(true);
            await this.apiRequest('/apply_tag', 'POST', {
                mac: this.currentDevice.mac,
                tag: tag,
                name: name || this.currentDevice.name
            });

            this.showMessage(`Tag "${tag}" applied to device successfully`, 'success');
            this.hideQuickAssign();
            await this.loadDevices();
        } catch (error) {
            this.showMessage('Error applying tag: ' + error.message, 'error');
        } finally {
            this.showLoading(false);
        }
    }

    showCreateTagForm() {
        document.getElementById('create-tag-form').style.display = 'block';
        document.getElementById('tag-name').focus();
        document.getElementById('create-tag-form').scrollIntoView({ behavior: 'smooth' });
    }

    hideCreateTagForm() {
        document.getElementById('create-tag-form').style.display = 'none';
        document.getElementById('create-tag-form').querySelectorAll('input').forEach(input => {
            input.value = '';
        });
    }

    async saveTag() {
        const name = document.getElementById('tag-name').value.trim();
        const gateway = document.getElementById('tag-gateway').value.trim();
        const dns = document.getElementById('tag-dns').value.trim();
        const description = document.getElementById('tag-description').value.trim();

        if (!name) {
            this.showMessage('Tag name is required', 'warning');
            return;
        }

        if (!/^[a-zA-Z0-9_-]{2,32}$/.test(name)) {
            this.showMessage('Invalid tag name. Use 2-32 characters (letters, numbers, underscore, hyphen only)', 'warning');
            return;
        }

        try {
            this.showLoading(true);
            await this.apiRequest('/create_tag', 'POST', {
                name,
                gateway,
                dns,
                description
            });

            this.showMessage(`Tag "${name}" created successfully`, 'success');
            this.hideCreateTagForm();
            await this.loadTags();
        } catch (error) {
            this.showMessage('Error creating tag: ' + error.message, 'error');
        } finally {
            this.showLoading(false);
        }
    }

    async deleteTag(tagName) {
        this.showConfirmModal(
            'Delete Tag',
            `Are you sure you want to delete the tag "${tagName}"? This action cannot be undone.`,
            async () => {
                try {
                    this.showLoading(true);
                    await this.apiRequest('/delete_tag', 'POST', { name: tagName });
                    this.showMessage(`Tag "${tagName}" deleted successfully`, 'success');
                    await this.loadTags();
                } catch (error) {
                    this.showMessage('Error deleting tag: ' + error.message, 'error');
                } finally {
                    this.showLoading(false);
                }
            }
        );
    }

    async discoverDevices() {
        this.showMessage('Device discovery started...', 'info');
        // Force refresh of devices to pick up any new ones
        await this.loadDevices();
        this.showMessage('Device discovery completed', 'success');
    }

    // Utility functions
    guessDeviceType(name, mac) {
        if (!this.deviceTypes) {
            return { icon: '💻', category: 'unknown' };
        }

        const macPrefix = mac.substring(0, 8).toUpperCase();
        if (this.deviceTypes.mac_prefixes[macPrefix]) {
            const vendor = this.deviceTypes.mac_prefixes[macPrefix];
            // Try to determine category based on vendor
            for (const [category, info] of Object.entries(this.deviceTypes.device_categories)) {
                if (info.keywords.some(keyword => vendor.toLowerCase().includes(keyword))) {
                    return { icon: info.icon, category };
                }
            }
        }

        // Check device name for keywords
        const lowerName = name.toLowerCase();
        for (const [category, info] of Object.entries(this.deviceTypes.device_categories)) {
            if (info.keywords.some(keyword => lowerName.includes(keyword))) {
                return { icon: info.icon, category };
            }
        }

        return { icon: '💻', category: 'unknown' };
    }

    getDeviceTag(mac) {
        const device = this.currentData.devices.find(d => d.mac.toLowerCase() === mac.toLowerCase());
        return device ? device.tag : 'default';
    }

    countDevicesWithTag(tag) {
        return this.currentData.devices.filter(d => 
            d.tag === tag || (tag === 'default' && (!d.tag || d.tag === 'default'))
        ).length;
    }

    showMessage(message, type = 'info') {
        const container = document.getElementById('status-messages');
        const messageEl = document.createElement('div');
        messageEl.className = `status-message status-${type}`;
        messageEl.textContent = message;

        container.appendChild(messageEl);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (messageEl.parentNode) {
                messageEl.parentNode.removeChild(messageEl);
            }
        }, 5000);
    }

    showLoading(show) {
        document.getElementById('loading-modal').style.display = show ? 'flex' : 'none';
    }

    showConfirmModal(title, message, callback) {
        document.getElementById('confirm-title').textContent = title;
        document.getElementById('confirm-message').textContent = message;
        document.getElementById('confirm-modal').style.display = 'flex';
        this.confirmCallback = callback;
    }

    hideConfirmModal() {
        document.getElementById('confirm-modal').style.display = 'none';
        this.confirmCallback = null;
    }

    async confirmAction() {
        if (this.confirmCallback) {
            await this.confirmCallback();
        }
        this.hideConfirmModal();
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    updateLastUpdateTime() {
        document.getElementById('last-update').textContent = 
            'Last updated: ' + new Date().toLocaleTimeString();
    }

    startAutoRefresh() {
        // Refresh every 30 seconds
        this.refreshInterval = setInterval(() => {
            if (document.visibilityState === 'visible') {
                this.loadStats();
                this.loadLeases();
            }
        }, 30000);
    }

    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dhcpManager = new EnhancedDHCPManager();
});

// Handle page visibility changes
document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && window.dhcpManager) {
        // Refresh data when page becomes visible
        window.dhcpManager.loadAllData();
    }
});