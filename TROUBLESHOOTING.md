# Enhanced DHCP 故障排除指南

## 🚨 安装问题

### 问题：IPK 包安装失败 "Malformed package file"

**错误信息**：
```
Collected errors:
* pkg_init_from_file: Malformed package file /tmp/upload.ipk.
opkg install 命令失败，代码 255。
```

**原因分析**：
这个错误通常是由于 IPK 包格式不完全兼容某些 OpenWrt 版本导致的。

**解决方案**：

#### 方案 1：使用兼容的 IPK 包
我们提供了专门为 OpenWrt 优化的构建脚本：

```bash
# 重新构建兼容的 IPK 包
./build-openwrt-ipk.sh
```

#### 方案 2：手动验证包完整性
```bash
# 检查包结构
ar t enhanced-dhcp_1.0.0-1_all.ipk

# 应该显示：
# debian-binary
# control.tar.gz  
# data.tar.gz

# 检查包大小
ls -lh enhanced-dhcp_1.0.0-1_all.ipk
```

#### 方案 3：通过命令行安装
如果 Web 界面安装失败，尝试 SSH 命令行：

```bash
# 1. 上传到路由器
scp enhanced-dhcp_1.0.0-1_all.ipk root@192.168.1.1:/tmp/

# 2. SSH 连接路由器
ssh root@192.168.1.1

# 3. 检查包完整性
opkg info /tmp/enhanced-dhcp_1.0.0-1_all.ipk

# 4. 强制安装
opkg install /tmp/enhanced-dhcp_1.0.0-1_all.ipk --force-reinstall
```

#### 方案 4：检查 OpenWrt 版本兼容性
```bash
# 检查 OpenWrt 版本
cat /etc/openwrt_release

# 检查 opkg 版本
opkg --version
```

**兼容版本**：
- OpenWrt 19.07+
- OpenWrt 21.02+  
- OpenWrt 22.03+
- OpenWrt 23.05+

## 🔧 运行时问题

### 问题：Web 界面无法访问

**症状**：安装成功但 LuCI 中找不到 "Enhanced DHCP" 菜单

**解决方案**：

1. **重启 LuCI 服务**：
   ```bash
   /etc/init.d/uhttpd restart
   ```

2. **清除浏览器缓存**：
   - 按 Ctrl+F5 强制刷新
   - 清除浏览器缓存和 Cookie

3. **检查服务状态**：
   ```bash
   /etc/init.d/enhanced_dhcp status
   ```

4. **手动启动服务**：
   ```bash
   /etc/init.d/enhanced_dhcp start
   ```

### 问题：DHCP 标签不生效

**症状**：创建了标签但设备没有获得正确的网络设置

**解决方案**：

1. **重启 dnsmasq 服务**：
   ```bash
   /etc/init.d/dnsmasq restart
   ```

2. **检查配置文件**：
   ```bash
   # 查看 DHCP 配置
   uci show dhcp
   
   # 查看增强 DHCP 配置
   uci show enhanced_dhcp
   ```

3. **强制设备重新获取 IP**：
   - 断开设备网络连接
   - 等待 30 秒
   - 重新连接网络

4. **检查 DHCP 租约**：
   ```bash
   cat /var/dhcp.leases
   ```

### 问题：设备发现功能不工作

**症状**：点击"发现设备"没有显示任何设备

**解决方案**：

1. **检查网络连接**：
   ```bash
   # 查看 ARP 表
   cat /proc/net/arp
   
   # 查看网络接口
   ip addr show
   ```

2. **ping 网络设备**：
   ```bash
   # ping 网段中的设备
   for i in {1..254}; do ping -c 1 -W 1 192.168.1.$i >/dev/null && echo "192.168.1.$i is alive"; done
   ```

3. **重启网络服务**：
   ```bash
   /etc/init.d/network restart
   ```

## 📋 配置问题

### 问题：无法保存配置

**错误信息**：配置保存时显示错误

**解决方案**：

1. **检查存储空间**：
   ```bash
   df -h
   ```

2. **检查配置文件权限**：
   ```bash
   ls -la /etc/config/
   ```

3. **手动备份和恢复**：
   ```bash
   # 备份配置
   cp /etc/config/dhcp /tmp/dhcp.backup
   
   # 恢复配置
   cp /tmp/dhcp.backup /etc/config/dhcp
   ```

### 问题：日志文件过大

**症状**：系统运行缓慢，存储空间不足

**解决方案**：

1. **清理日志文件**：
   ```bash
   # 清理增强 DHCP 日志
   > /var/log/enhanced_dhcp.log
   
   # 清理系统日志
   logread -f > /dev/null &
   ```

2. **配置日志轮转**：
   ```bash
   # 编辑配置
   uci set enhanced_dhcp.logging.max_log_size='512'
   uci commit enhanced_dhcp
   ```

## 🛠️ 高级故障排除

### 调试模式

启用详细日志记录：

```bash
# 设置调试级别
uci set enhanced_dhcp.global.log_level='debug'
uci commit enhanced_dhcp

# 重启服务
/etc/init.d/enhanced_dhcp restart

# 查看详细日志
tail -f /var/log/enhanced_dhcp.log
```

### 完全重置

如果遇到严重问题，可以完全重置：

```bash
# 1. 停止服务
/etc/init.d/enhanced_dhcp stop

# 2. 备份当前配置
cp /etc/config/dhcp /tmp/dhcp.original
cp /etc/config/enhanced_dhcp /tmp/enhanced_dhcp.original

# 3. 重新安装包
opkg remove enhanced-dhcp
opkg install /tmp/enhanced-dhcp_1.0.0-1_all.ipk

# 4. 重启相关服务
/etc/init.d/enhanced_dhcp start
/etc/init.d/dnsmasq restart
/etc/init.d/uhttpd restart
```

### 获取技术支持

如果问题仍然存在，请收集以下信息：

```bash
# 系统信息
cat /etc/openwrt_release
uname -a

# 服务状态
/etc/init.d/enhanced_dhcp status
/etc/init.d/dnsmasq status

# 配置转储
uci show dhcp > /tmp/dhcp_config.txt
uci show enhanced_dhcp > /tmp/enhanced_dhcp_config.txt

# 日志文件
cp /var/log/enhanced_dhcp.log /tmp/
logread > /tmp/system.log
```

然后在 [GitHub Issues](https://github.com/morefreefg/enhanced-dhcp/issues) 中提交问题报告，包含上述信息。

## 📞 社区支持

- **GitHub Issues**: https://github.com/morefreefg/enhanced-dhcp/issues
- **文档**: https://github.com/morefreefg/enhanced-dhcp/wiki
- **OpenWrt 论坛**: https://forum.openwrt.org/

---

**注意**：在提交问题前，请先尝试上述解决方案，并确保使用的是最新版本的软件包。