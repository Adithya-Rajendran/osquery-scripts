#!/bin/bash

# Define output directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
HOSTNAME=$(hostname)
OUTPUT_DIR="snapshot_${HOSTNAME}_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

echo "Starting System Snapshot for $HOSTNAME..."
echo "Output directory: $OUTPUT_DIR"

# ==========================================
# 1. CORE SYSTEM INFO
# ==========================================

# Network Interfaces (FIXED QUERY)
# Uses a JOIN to ensure we get MTU and Addresses together, filters out loopbacks.
echo "Gathering Interface & MTU info..."
osqueryi --json "SELECT id.interface, id.mtu, id.mac, ia.address, ia.mask FROM interface_details id JOIN interface_addresses ia ON id.interface = ia.interface WHERE ia.address NOT LIKE '127.%' AND ia.address NOT LIKE '%:%';" > "$OUTPUT_DIR/network_interfaces.json"

# OS & Kernel Info
echo "Gathering OS & Kernel info..."
osqueryi --json "SELECT os.name, os.version, k.version AS kernel_version, si.cpu_physical_cores, si.physical_memory FROM os_version os, kernel_info k, system_info si;" > "$OUTPUT_DIR/system_info.json"

# ==========================================
# 2. PROCESSES & NETWORK
# ==========================================

# Listening Ports
echo "Gathering Listening Ports..."
osqueryi --json "SELECT lp.port, lp.protocol, p.name AS process, p.path, p.cmdline FROM listening_ports lp JOIN processes p ON lp.pid = p.pid WHERE lp.address != '127.0.0.1';" > "$OUTPUT_DIR/listening_ports.json"

# Active Connections
echo "Gathering Active Connections..."
osqueryi --json "SELECT pos.local_port, pos.remote_address, pos.remote_port, p.name AS process FROM process_open_sockets pos JOIN processes p ON pos.pid = p.pid WHERE pos.remote_port > 0 AND pos.state = 'ESTABLISHED';" > "$OUTPUT_DIR/active_connections.json"

# Firewall Rules (NEW)
echo "Gathering Firewall (IPTables) Rules..."
osqueryi --json "SELECT chain, policy, src_ip, dst_ip, protocol, target FROM iptables;" > "$OUTPUT_DIR/iptables.json"

# ==========================================
# 3. STORAGE & PACKAGES
# ==========================================

# Mounted Filesystems
echo "Gathering Storage Mounts..."
osqueryi --json "SELECT device, path, type, blocks_size * blocks_free AS free_bytes FROM mounts WHERE type NOT IN ('proc', 'sysfs', 'cgroup', 'tmpfs', 'devtmpfs', 'autofs', 'overlay');" > "$OUTPUT_DIR/storage_mounts.json"

# Installed Packages
echo "Gathering Installed Packages..."
osqueryi --json "SELECT name, version, 'deb' as type FROM deb_packages UNION SELECT name, version, 'rpm' as type FROM rpm_packages;" > "$OUTPUT_DIR/installed_packages.json"

# Users
echo "Gathering User Accounts..."
osqueryi --json "SELECT username, uid, gid, shell FROM users WHERE shell NOT LIKE '%/nologin' AND shell NOT LIKE '%/false';" > "$OUTPUT_DIR/users.json"

# ==========================================
# 4. TASKS & SERVICES (NEW SECTION)
# ==========================================

# Scheduled Tasks (Cron)
echo "Gathering Cron Jobs..."
osqueryi --json "SELECT command, path, month, day_of_month, hour, minute FROM crontab;" > "$OUTPUT_DIR/crontab.json"

# Systemd Timers (Modern Cron)
echo "Gathering Systemd Timers..."
osqueryi --json "SELECT id, description, sub_state, active_state FROM systemd_units WHERE id LIKE '%.timer';" > "$OUTPUT_DIR/systemd_timers.json"

# Failed Services (To detect broken apps)
echo "Gathering Failed Services..."
osqueryi --json "SELECT id, sub_state, description FROM systemd_units WHERE active_state = 'failed' OR sub_state = 'dead';" > "$OUTPUT_DIR/failed_services.json"

# Running Services
echo "Gathering Services..."
osqueryi --json "SELECT id, sub_state, description FROM systemd_units WHERE active_state = 'active' OR sub_state = 'running';" > "$OUTPUT_DIR/services.json"

# CNI Configuration Check (To explain veth interfaces)
# We use the 'file' table to list configs instead of 'ls'
echo "Gathering CNI Configuration Files..."
osqueryi --json "SELECT path, filename, size, mtime FROM file WHERE directory = '/etc/cni/net.d/';" > "$OUTPUT_DIR/cni_configs.json"

# ==========================================
# 5. CONTAINER RUNTIMES
# ==========================================

# DOCKER CHECK
if [ -S /var/run/docker.sock ]; then
    echo "🐳 Docker Socket found. Gathering Docker info..."
    osqueryi --json "SELECT * FROM docker_info;" > "$OUTPUT_DIR/docker_info.json"
    osqueryi --json "SELECT id, name, image, status, command, env FROM docker_containers;" > "$OUTPUT_DIR/docker_containers.json"
    osqueryi --json "SELECT name, driver, subnet, gateway FROM docker_networks;" > "$OUTPUT_DIR/docker_networks.json"
    osqueryi --json "SELECT name, driver, mount_point FROM docker_volumes;" > "$OUTPUT_DIR/docker_volumes.json"
else
    echo "Docker socket not found. Skipping."
fi

# ==========================================
# 6. FINALIZE
# ==========================================

echo "Compressing results..."
tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"

echo "---------------------------------------------------"
echo "Snapshot Complete: ${OUTPUT_DIR}.tar.gz"
echo "---------------------------------------------------"