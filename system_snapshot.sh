#!/bin/bash

# 1. Setup
HOSTNAME=$(hostname)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
QUERY_DIR="./queries"
OUTPUT_DIR="snapshot_${HOSTNAME}_${TIMESTAMP}"

# Ensure query directory exists
if [ ! -d "$QUERY_DIR" ]; then
    echo "❌ Error: Directory '$QUERY_DIR' not found."
    echo "Please run the generate_queries.sh script first."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
echo "Starting System Snapshot for $HOSTNAME..."
echo "Reading queries from: $QUERY_DIR"
echo "Output directory: $OUTPUT_DIR"

# Function to run a query from a file
# Usage: run_query "filename.sql" "output_filename.json" "Description"
run_query() {
    local sql_file=$1
    local out_file=$2
    local desc=$3

    if [ -f "$QUERY_DIR/$sql_file" ]; then
        echo "   Running: $desc"
        # We pipe the file content into osqueryi
        osqueryi --json < "$QUERY_DIR/$sql_file" > "$OUTPUT_DIR/$out_file"
    else
        echo "⚠️  Warning: $sql_file not found. Skipping."
    fi
}

# ==========================================
# 2. STANDARD CHECKS (Always Run)
# ==========================================
echo "---------------------------------"
echo "Phase 1: Standard System Checks"
echo "---------------------------------"

run_query "network_interfaces.sql"  "network_interfaces.json"  "Network Interfaces & MTU"
run_query "system_info.sql"         "system_info.json"         "OS & Hardware Info"
run_query "listening_ports.sql"     "listening_ports.json"     "Listening Ports"
run_query "active_connections.sql"  "active_connections.json"  "Active Connections"
run_query "iptables.sql"            "iptables.json"            "Firewall Rules"
run_query "storage_mounts.sql"      "storage_mounts.json"      "Storage Mounts"
run_query "installed_packages.sql"  "installed_packages.json"  "Installed Packages"
run_query "users.sql"               "users.json"               "User Accounts"
run_query "crontab.sql"             "crontab.json"             "Cron Jobs"
run_query "systemd_timers.sql"      "systemd_timers.json"      "Systemd Timers"
run_query "active_services.sql"     "active_services.json"     "Active Services"
run_query "failed_services.sql"     "failed_services.json"     "Failed Services"
run_query "cni_configs.sql"         "cni_configs.json"         "CNI/K8s Artifacts"

# ==========================================
# 3. CONTAINER CHECKS (Conditional)
# ==========================================
echo "---------------------------------"
echo "Phase 2: Container Runtimes"
echo "---------------------------------"

# --- DOCKER ---
if [ -S /var/run/docker.sock ]; then
    echo "🐳 Docker Socket found. Running Docker queries..."
    run_query "docker_info.sql"       "docker_info.json"       "Docker Info"
    run_query "docker_containers.sql" "docker_containers.json" "Docker Containers"
    run_query "docker_networks.sql"   "docker_networks.json"   "Docker Networks"
    run_query "docker_volumes.sql"    "docker_volumes.json"    "Docker Volumes"
else
    echo "⚪ Docker socket not found. Skipping Docker queries."
fi

# ==========================================
# 4. FINALIZE
# ==========================================
echo "---------------------------------"
echo "Compressing results..."
tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"

echo "✅ Snapshot Complete: ${OUTPUT_DIR}.tar.gz"